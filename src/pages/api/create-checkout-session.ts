// Create Stripe Checkout Session
// POST /api/create-checkout-session
// Body: { productSlug: string }
// Returns: { url: string } (redirect to Stripe)

import type { APIRoute } from 'astro'
import Stripe from 'stripe'
import { STRIPE_SECRET_KEY } from 'astro:env/server'
import { createClient } from '@supabase/supabase-js'
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_PUBLISHABLE_KEY } from 'astro:env/client'

const stripe = new Stripe(STRIPE_SECRET_KEY, {
  apiVersion: '2025-12-15.clover',
})

export const POST: APIRoute = async ({ request, url }) => {
  try {
    // Parse request body
    const { productSlug } = await request.json()

    if (!productSlug) {
      return new Response(JSON.stringify({ error: 'Missing productSlug' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Get user auth token (if logged in)
    const authHeader = request.headers.get('Authorization')
    const token = authHeader?.replace('Bearer ', '')

    // Create client-side Supabase client using user's token
    // This respects RLS policies - we trust the database, not the server
    const supabase = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_PUBLISHABLE_KEY, {
      global: {
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      },
    })

    // Get product from database (RLS allows public reads)
    const { data: product, error: productError } = await supabase
      .from('products')
      .select('id, title, price_cents, slug')
      .eq('slug', productSlug)
      .single()

    if (productError || !product) {
      return new Response(JSON.stringify({ error: 'Product not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    let userId: string | null = null
    let customerEmail: string | null = null

    if (token) {
      // Get user from token (respects RLS)
      const { data: { user } } = await supabase.auth.getUser(token)
      userId = user?.id || null
      customerEmail = user?.email || null

      // Check if user already owns this product (RLS allows users to see their own purchases)
      if (userId) {
        const { data: existingPurchase } = await supabase
          .from('purchases')
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', product.id)
          .single()

        if (existingPurchase) {
          return new Response(
            JSON.stringify({ error: 'You already own this album' }),
            {
              status: 400,
              headers: { 'Content-Type': 'application/json' },
            }
          )
        }
      }
    }

    // Create Stripe Checkout Session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      link: null, // Disable Stripe Link integration
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: product.title,
              description: `Lifetime access to ${product.title} (FLAC)`,
            },
            unit_amount: product.price_cents,
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      success_url: `${url.origin}/${product.slug}?success=true`,
      cancel_url: `${url.origin}/${product.slug}?canceled=true`,
      customer_email: customerEmail || undefined,
      metadata: {
        product_id: product.id,
        product_slug: product.slug,
        user_id: userId || '',
      },
    })

    return new Response(JSON.stringify({ url: session.url }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (err: any) {
    console.error('Checkout session error:', err)
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
}
