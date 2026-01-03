// Stripe Webhook Handler
// POST /api/stripe-webhook
// Handles payment confirmation and order fulfillment

import type { APIRoute } from 'astro'
import Stripe from 'stripe'
import { STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET } from 'astro:env/server'
import { supabaseAdmin } from '@/lib/supabase-server'

const stripe = new Stripe(STRIPE_SECRET_KEY, {
  apiVersion: '2025-01-27.acacia',
})

export const POST: APIRoute = async ({ request }) => {
  const payload = await request.text()
  const signature = request.headers.get('stripe-signature')

  if (!signature) {
    return new Response('Missing signature', { status: 400 })
  }

  let event: Stripe.Event

  try {
    // Verify webhook signature
    event = stripe.webhooks.constructEvent(
      payload,
      signature,
      STRIPE_WEBHOOK_SECRET
    )
  } catch (err: any) {
    console.error('Webhook signature verification failed:', err.message)
    return new Response(`Webhook Error: ${err.message}`, { status: 400 })
  }

  // Handle checkout.session.completed event
  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session

    try {
      await fulfillOrder(session)
    } catch (err: any) {
      console.error('Order fulfillment failed:', err)
      return new Response(`Fulfillment Error: ${err.message}`, { status: 500 })
    }
  }

  return new Response(JSON.stringify({ received: true }), { status: 200 })
}

async function fulfillOrder(session: Stripe.Checkout.Session) {
  const productId = session.metadata?.product_id
  const userId = session.metadata?.user_id
  const priceInCents = session.amount_total || 0

  if (!productId) {
    throw new Error('Missing product_id in session metadata')
  }

  console.log(`Fulfilling order for session: ${session.id}`)
  console.log(`  Product ID: ${productId}`)
  console.log(`  User ID: ${userId || 'Guest'}`)
  console.log(`  Amount: $${(priceInCents / 100).toFixed(2)}`)

  // Determine user_id
  let finalUserId = userId

  // If user wasn't logged in during checkout, find/create by email
  if (!finalUserId && session.customer_email) {
    console.log(`  Finding/creating user for email: ${session.customer_email}`)

    // Check if user exists with this email
    const { data: existingUser } = await supabaseAdmin.auth.admin.getUserByEmail(
      session.customer_email
    )

    if (existingUser?.user) {
      finalUserId = existingUser.user.id
      console.log(`  Found existing user: ${finalUserId}`)
    } else {
      // Create user account (they'll verify email to access)
      const { data: newUser, error } = await supabaseAdmin.auth.admin.createUser({
        email: session.customer_email,
        email_confirm: false, // They'll get verification email
      })

      if (error) {
        console.error(`  Failed to create user:`, error)
        throw error
      }

      finalUserId = newUser.user.id
      console.log(`  Created new user: ${finalUserId}`)
    }
  }

  if (!finalUserId) {
    throw new Error('Could not determine user_id for purchase')
  }

  // Insert purchase record (idempotent via stripe_session_id unique constraint)
  const { error } = await supabaseAdmin
    .from('purchases')
    .upsert(
      {
        user_id: finalUserId,
        product_id: productId,
        price_paid_cents: priceInCents,
        stripe_session_id: session.id,
        stripe_payment_intent_id: session.payment_intent as string,
      },
      {
        onConflict: 'stripe_session_id',
        ignoreDuplicates: true, // Don't error if already exists
      }
    )

  if (error) {
    console.error('Purchase insert error:', error)
    throw error
  }

  console.log(`✓ Order fulfilled successfully`)
  console.log(`  Session: ${session.id}`)
  console.log(`  User: ${finalUserId}`)
  console.log(`  Product: ${productId}`)
}
