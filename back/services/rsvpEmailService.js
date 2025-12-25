const nodemailer = require('nodemailer');

class RSVPEmailService {
    constructor() {
        // Create transporter using Gmail
        this.transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
                user: process.env.GMAIL_USER,
                pass: process.env.GMAIL_APP_PASSWORD
            }
        });
    }

    /**
     * Send RSVP confirmation email to user after booking
     */
    async sendRSVPConfirmation(booking, event, user) {
        try {
            const eventDate = new Date(event.eventDateTime);
            const formattedDate = eventDate.toLocaleDateString('en-US', {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric'
            });
            const formattedTime = eventDate.toLocaleTimeString('en-US', {
                hour: '2-digit',
                minute: '2-digit'
            });

            let bookingDetails = '';
            if (booking.bookingType === 'seat') {
                bookingDetails = `
                    <p><strong>Booking Type:</strong> Seat Reservation</p>
                    <p><strong>Seat Number:</strong> ${booking.ticketOrSeatNumber}</p>
                `;
            } else {
                bookingDetails = `
                    <p><strong>Booking Type:</strong> Ticket Purchase</p>
                    <p><strong>Ticket Number:</strong> ${booking.ticketOrSeatNumber}</p>
                    <p><strong>Price:</strong> PKR ${event.ticketPrice || 'N/A'}</p>
                `;
            }

            const mailOptions = {
                from: `"AutoVisionHub Events" <${process.env.GMAIL_USER}>`,
                to: user.email,
                subject: `🎉 RSVP Confirmation - ${event.eventName}`,
                html: `
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <style>
                            body {
                                font-family: Arial, sans-serif;
                                line-height: 1.6;
                                color: #333;
                            }
                            .container {
                                max-width: 600px;
                                margin: 0 auto;
                                padding: 20px;
                                background-color: #f9f9f9;
                            }
                            .header {
                                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                                color: white;
                                padding: 30px;
                                text-align: center;
                                border-radius: 10px 10px 0 0;
                            }
                            .content {
                                background-color: white;
                                padding: 30px;
                                border-radius: 0 0 10px 10px;
                            }
                            .event-details {
                                background-color: #f0f0f0;
                                padding: 20px;
                                border-radius: 8px;
                                margin: 20px 0;
                            }
                            .footer {
                                text-align: center;
                                padding: 20px;
                                color: #777;
                                font-size: 14px;
                            }
                            .button {
                                display: inline-block;
                                padding: 12px 30px;
                                background-color: #667eea;
                                color: white;
                                text-decoration: none;
                                border-radius: 5px;
                                margin-top: 20px;
                            }
                        </style>
                    </head>
                    <body>
                        <div class="container">
                            <div class="header">
                                <h1>🎉 Your RSVP is Confirmed!</h1>
                            </div>
                            <div class="content">
                                <p>Dear ${user.name},</p>
                                <p>Thank you for booking! Your reservation for <strong>${event.eventName}</strong> has been confirmed.</p>
                                
                                <div class="event-details">
                                    <h2>📅 Event Details</h2>
                                    <p><strong>Event:</strong> ${event.eventName}</p>
                                    <p><strong>Date:</strong> ${formattedDate}</p>
                                    <p><strong>Time:</strong> ${formattedTime}</p>
                                    <p><strong>Location:</strong> ${event.eventLocation}</p>
                                    <p><strong>Description:</strong> ${event.eventDescription}</p>
                                    
                                    <hr style="margin: 20px 0; border: none; border-top: 1px solid #ddd;">
                                    
                                    <h2>🎫 Your Booking</h2>
                                    <p><strong>Booking ID:</strong> ${booking._id}</p>
                                    ${bookingDetails}
                                    <p><strong>Total Amount:</strong> PKR ${booking.totalAmount}</p>
                                </div>
                                
                                <p><strong>Important Notes:</strong></p>
                                <ul>
                                    <li>Please arrive 15 minutes before the event starts</li>
                                    <li>Keep this email as your booking confirmation</li>
                                    <li>Contact the event organizer if you have any questions</li>
                                </ul>
                                
                                <p>We look forward to seeing you at the event!</p>
                                
                                <p>Best regards,<br>
                                <strong>AutoVisionHub Team</strong></p>
                            </div>
                            <div class="footer">
                                <p>This is an automated confirmation email. Please do not reply to this message.</p>
                                <p>&copy; ${new Date().getFullYear()} AutoVisionHub. All rights reserved.</p>
                            </div>
                        </div>
                    </body>
                    </html>
                `
            };

            const info = await this.transporter.sendMail(mailOptions);
            console.log('✅ RSVP email sent successfully:', info.messageId);
            return { success: true, messageId: info.messageId };

        } catch (error) {
            console.error('❌ Error sending RSVP email:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Send event reminder email (optional - can be scheduled 1 day before event)
     */
    async sendEventReminder(booking, event, user) {
        try {
            const eventDate = new Date(event.eventDateTime);
            const formattedDate = eventDate.toLocaleDateString('en-US', {
                weekday: 'long',
                month: 'long',
                day: 'numeric'
            });
            const formattedTime = eventDate.toLocaleTimeString('en-US', {
                hour: '2-digit',
                minute: '2-digit'
            });

            const mailOptions = {
                from: `"AutoVisionHub Events" <${process.env.GMAIL_USER}>`,
                to: user.email,
                subject: `🔔 Reminder: ${event.eventName} - Tomorrow!`,
                html: `
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <style>
                            body {
                                font-family: Arial, sans-serif;
                                line-height: 1.6;
                                color: #333;
                            }
                            .container {
                                max-width: 600px;
                                margin: 0 auto;
                                padding: 20px;
                            }
                            .reminder-box {
                                background-color: #fff3cd;
                                border-left: 4px solid #ffc107;
                                padding: 20px;
                                margin: 20px 0;
                            }
                        </style>
                    </head>
                    <body>
                        <div class="container">
                            <h1>🔔 Event Reminder</h1>
                            <p>Hi ${user.name},</p>
                            <p>This is a friendly reminder that your event is coming up tomorrow!</p>
                            
                            <div class="reminder-box">
                                <h2>${event.eventName}</h2>
                                <p><strong>📅 Date:</strong> ${formattedDate}</p>
                                <p><strong>🕐 Time:</strong> ${formattedTime}</p>
                                <p><strong>📍 Location:</strong> ${event.eventLocation}</p>
                            </div>
                            
                            <p>Don't forget to arrive 15 minutes early!</p>
                            <p>See you there!</p>
                            
                            <p>Best regards,<br>AutoVisionHub Team</p>
                        </div>
                    </body>
                    </html>
                `
            };

            const info = await this.transporter.sendMail(mailOptions);
            console.log('✅ Reminder email sent successfully:', info.messageId);
            return { success: true, messageId: info.messageId };

        } catch (error) {
            console.error('❌ Error sending reminder email:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Test email configuration
     */
    async testConnection() {
        try {
            await this.transporter.verify();
            console.log('✅ SMTP connection verified successfully');
            return true;
        } catch (error) {
            console.error('❌ SMTP connection failed:', error);
            return false;
        }
    }
}

module.exports = new RSVPEmailService();
