// Contact form submission endpoint
// POST /api/contact
// Body: { name?: string, email?: string, message: string }
// Returns: { success: boolean }

import type { APIRoute } from 'astro'
import { Resend } from 'resend'
import { RESEND_API_KEY, CONTACT_EMAIL } from 'astro:env/server'

const resend = new Resend(RESEND_API_KEY)

export const POST: APIRoute = async ({ request }) => {
  try {
    // Parse request body
    const { name, email, message } = await request.json()

    // Validate required fields
    if (!message || message.trim().length === 0) {
      return new Response(
        JSON.stringify({ message: 'Message is required' }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        }
      )
    }

    // Validate message length (prevent abuse)
    if (message.length > 5000) {
      return new Response(
        JSON.stringify({ message: 'Message is too long (max 5000 characters)' }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        }
      )
    }

    // Send email via Resend
    const { error } = await resend.emails.send({
      from: 'Contact Form <bot@musicaluniversefactory.com>',
      to: CONTACT_EMAIL,
      subject: `New Contact Form Message${name ? ` from ${name}` : ''}`,
      html: `
        <h2>New Contact Form Submission</h2>
        <p><strong>Name:</strong> ${name || 'Not provided'}</p>
        <p><strong>Email:</strong> ${email || 'Not provided'}</p>
        <hr />
        <h3>Message:</h3>
        <p>${message.replace(/\n/g, '<br />')}</p>
      `,
      text: `
New Contact Form Submission

Name: ${name || 'Not provided'}
Email: ${email || 'Not provided'}

Message:
${message}
      `,
    })

    if (error) {
      console.error('Resend error:', error)
      return new Response(
        JSON.stringify({ message: 'Failed to send email' }),
        {
          status: 500,
          headers: { 'Content-Type': 'application/json' },
        }
      )
    }

    // Success response
    return new Response(
      JSON.stringify({ success: true }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    console.error('Contact form error:', error)
    return new Response(
      JSON.stringify({ message: 'An unexpected error occurred' }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    )
  }
}
