# 📧 Email Verification Patterns

## **Overview**

Email verification implementation using Better Auth with custom email templates, SMTP configuration, and production-ready patterns for enterprise applications.

---

## 🔧 **Email Service Setup**

### **SMTP Configuration**

```typescript
// lib/email/smtp.ts
import nodemailer from "nodemailer";

const transporter = nodemailer.createTransporter({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT || "587"),
  secure: process.env.SMTP_PORT === "465", // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

export async function sendEmail({
  to,
  subject,
  html,
  text,
}: {
  to: string;
  subject: string;
  html: string;
  text?: string;
}) {
  try {
    const info = await transporter.sendMail({
      from: process.env.SMTP_FROM || "noreply@company.com",
      to,
      subject,
      html,
      text: text || html.replace(/<[^>]*>/g, ""), // Strip HTML for text version
    });

    console.log("Email sent successfully:", info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error("Email sending failed:", error);
    return { success: false, error };
  }
}

// Verify SMTP connection
export async function verifyEmailConnection() {
  try {
    await transporter.verify();
    console.log("SMTP connection verified successfully");
    return true;
  } catch (error) {
    console.error("SMTP connection failed:", error);
    return false;
  }
}
```

---

## 📨 **Email Templates**

### **Verification Email Template**

```typescript
// lib/email/templates/verification.ts
export function generateVerificationEmail({
  name,
  verifyUrl,
  companyName = "Your Company",
}: {
  name: string;
  verifyUrl: string;
  companyName?: string;
}) {
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Verify Your Email</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          line-height: 1.6;
          color: #333;
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
        }
        .header {
          background-color: #f8f9fa;
          padding: 20px;
          text-align: center;
          border-radius: 8px 8px 0 0;
        }
        .content {
          background-color: #ffffff;
          padding: 30px;
          border: 1px solid #e9ecef;
        }
        .footer {
          background-color: #f8f9fa;
          padding: 20px;
          text-align: center;
          border-radius: 0 0 8px 8px;
          font-size: 14px;
          color: #666;
        }
        .button {
          display: inline-block;
          background-color: #007bff;
          color: white;
          text-decoration: none;
          padding: 12px 24px;
          border-radius: 6px;
          margin: 20px 0;
          font-weight: bold;
        }
        .button:hover {
          background-color: #0056b3;
        }
        .code {
          background-color: #f8f9fa;
          padding: 10px;
          border-radius: 4px;
          font-family: monospace;
          font-size: 16px;
          text-align: center;
          margin: 20px 0;
        }
      </style>
    </head>
    <body>
      <div class="header">
        <h1>${companyName}</h1>
      </div>
      
      <div class="content">
        <h2>Welcome, ${name}!</h2>
        
        <p>Thank you for signing up. To complete your registration and start using your account, please verify your email address by clicking the button below:</p>
        
        <div style="text-align: center;">
          <a href="${verifyUrl}" class="button">Verify Email Address</a>
        </div>
        
        <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
        <div class="code">${verifyUrl}</div>
        
        <p><strong>Security Note:</strong> This verification link will expire in 24 hours for security reasons. If you didn't create an account with us, you can safely ignore this email.</p>
        
        <p>If you have any questions or need assistance, please don't hesitate to contact our support team.</p>
        
        <p>Best regards,<br>The ${companyName} Team</p>
      </div>
      
      <div class="footer">
        <p>This is an automated email. Please do not reply to this message.</p>
        <p>&copy; ${new Date().getFullYear()} ${companyName}. All rights reserved.</p>
      </div>
    </body>
    </html>
  `;

  const text = `
    Welcome to ${companyName}, ${name}!
    
    Thank you for signing up. To complete your registration, please verify your email address by visiting this link:
    
    ${verifyUrl}
    
    This verification link will expire in 24 hours for security reasons.
    
    If you didn't create an account with us, you can safely ignore this email.
    
    Best regards,
    The ${companyName} Team
  `;

  return { html, text };
}
```

---

## 📤 **Email Service Implementation**

### **Verification Email Sender**

```typescript
// lib/email/send-verification.ts
import { sendEmail } from "./smtp";
import { generateVerificationEmail } from "./templates/verification";

export async function sendVerificationEmail({
  to,
  name,
  verifyUrl,
}: {
  to: string;
  name: string;
  verifyUrl: string;
}) {
  const { html, text } = generateVerificationEmail({
    name,
    verifyUrl,
    companyName: process.env.COMPANY_NAME || "Your Company",
  });

  const result = await sendEmail({
    to,
    subject: "Verify your email address",
    html,
    text,
  });

  if (!result.success) {
    console.error("Failed to send verification email:", result.error);
    throw new Error("Failed to send verification email");
  }

  console.log(`Verification email sent to ${to}`);
  return result;
}

export async function resendVerificationEmail(userId: string) {
  try {
    // Get user data
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new Error("User not found");
    }

    if (user.emailVerified) {
      throw new Error("Email already verified");
    }

    // Generate new verification token
    const verification = await auth.api.sendVerificationEmail({
      body: { email: user.email },
    });

    return { success: true };
  } catch (error) {
    console.error("Failed to resend verification email:", error);
    throw error;
  }
}
```

---

## 🔗 **Verification Flow**

### **Verification API Route**

```typescript
// app/api/auth/verify/route.ts
import { NextRequest } from "next/server";
import { auth } from "@/lib/auth";

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const token = searchParams.get("token");
    const callbackURL = searchParams.get("callbackURL") || "/dashboard";

    if (!token) {
      return new Response("Verification token is required", { status: 400 });
    }

    // Verify the token using Better Auth
    const result = await auth.api.verifyEmail({
      body: { token },
    });

    if (!result.success) {
      return new Response("Invalid or expired verification token", { 
        status: 400 
      });
    }

    // Redirect to success page or dashboard
    return Response.redirect(new URL(callbackURL, req.url));
  } catch (error) {
    console.error("Email verification error:", error);
    return new Response("Verification failed", { status: 500 });
  }
}
```

### **Resend Verification API**

```typescript
// app/api/auth/resend-verification/route.ts
import { NextRequest } from "next/server";
import { withAuth } from "@/lib/api-auth";
import { resendVerificationEmail } from "@/lib/email/send-verification";

export const POST = withAuth(async (req, session) => {
  try {
    if (session.user.emailVerified) {
      return Response.json(
        { error: "Email already verified" },
        { status: 400 }
      );
    }

    await resendVerificationEmail(session.user.id);

    return Response.json({ 
      message: "Verification email sent successfully" 
    });
  } catch (error) {
    console.error("Resend verification error:", error);
    return Response.json(
      { error: "Failed to send verification email" },
      { status: 500 }
    );
  }
});
```

---

## 🎯 **Frontend Components**

### **Email Verification Banner**

```typescript
// components/auth/email-verification-banner.tsx
"use client";

import { useState } from "react";
import { useAuth } from "@/hooks/use-auth";
import { Button } from "@/components/ui/button";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Mail, RefreshCw } from "lucide-react";

export function EmailVerificationBanner() {
  const { user, isEmailVerified } = useAuth();
  const [isResending, setIsResending] = useState(false);
  const [message, setMessage] = useState("");

  // Don't show banner if email is verified or user not logged in
  if (!user || isEmailVerified) {
    return null;
  }

  const handleResendVerification = async () => {
    setIsResending(true);
    setMessage("");

    try {
      const response = await fetch("/api/auth/resend-verification", {
        method: "POST",
      });

      const data = await response.json();

      if (response.ok) {
        setMessage("Verification email sent! Check your inbox.");
      } else {
        setMessage(data.error || "Failed to send verification email");
      }
    } catch (error) {
      setMessage("An error occurred. Please try again.");
    } finally {
      setIsResending(false);
    }
  };

  return (
    <Alert className="mb-4 border-yellow-200 bg-yellow-50">
      <Mail className="h-4 w-4" />
      <AlertDescription className="flex items-center justify-between">
        <div>
          <strong>Email verification required.</strong> Please check your inbox and verify your email address to access all features.
        </div>
        <Button
          variant="outline"
          size="sm"
          onClick={handleResendVerification}
          disabled={isResending}
          className="ml-4"
        >
          {isResending ? (
            <>
              <RefreshCw className="mr-2 h-4 w-4 animate-spin" />
              Sending...
            </>
          ) : (
            "Resend Email"
          )}
        </Button>
      </AlertDescription>
      {message && (
        <div className="mt-2 text-sm text-gray-600">{message}</div>
      )}
    </Alert>
  );
}
```

### **Verification Success Page**

```typescript
// app/auth/verify/page.tsx
"use client";

import { useEffect, useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { CheckCircle, XCircle, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";

export default function VerifyEmailPage() {
  const [status, setStatus] = useState<"loading" | "success" | "error">("loading");
  const [message, setMessage] = useState("");
  const searchParams = useSearchParams();
  const router = useRouter();

  useEffect(() => {
    const token = searchParams.get("token");
    
    if (!token) {
      setStatus("error");
      setMessage("Verification token is missing");
      return;
    }

    // The verification is handled by the API route
    // This page just shows the result
    const result = searchParams.get("result");
    
    if (result === "success") {
      setStatus("success");
      setMessage("Email verified successfully!");
    } else if (result === "error") {
      setStatus("error");
      setMessage("Verification failed. The token may be invalid or expired.");
    }
  }, [searchParams]);

  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="text-center">
        {status === "loading" && (
          <>
            <Loader2 className="mx-auto h-16 w-16 animate-spin text-blue-500" />
            <h1 className="mt-4 text-2xl font-bold">Verifying Email...</h1>
            <p className="mt-2 text-gray-600">Please wait while we verify your email address.</p>
          </>
        )}

        {status === "success" && (
          <>
            <CheckCircle className="mx-auto h-16 w-16 text-green-500" />
            <h1 className="mt-4 text-2xl font-bold text-green-600">Email Verified!</h1>
            <p className="mt-2 text-gray-600">{message}</p>
            <Button 
              className="mt-4" 
              onClick={() => router.push("/dashboard")}
            >
              Continue to Dashboard
            </Button>
          </>
        )}

        {status === "error" && (
          <>
            <XCircle className="mx-auto h-16 w-16 text-red-500" />
            <h1 className="mt-4 text-2xl font-bold text-red-600">Verification Failed</h1>
            <p className="mt-2 text-gray-600">{message}</p>
            <div className="mt-4 space-x-2">
              <Button 
                variant="outline" 
                onClick={() => router.push("/login")}
              >
                Back to Login
              </Button>
              <Button 
                onClick={() => router.push("/auth/resend-verification")}
              >
                Request New Link
              </Button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
```

---

## 🔧 **Environment Configuration**

### **Required Environment Variables**

```bash
# .env.local

# SMTP Configuration
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=noreply@company.com
SMTP_PASS=your-smtp-password
SMTP_FROM=noreply@company.com

# Company Information
COMPANY_NAME="Your Company Name"

# Application URLs
NEXT_PUBLIC_APP_URL=https://yourapp.com

# Better Auth will use these for verification URLs
BETTER_AUTH_SECRET=your-secret-key
BETTER_AUTH_URL=https://yourapp.com
```

---

## 🧪 **Testing Email Verification**

### **Test Email Service**

```typescript
// __tests__/email/verification.test.ts
import { describe, it, expect, jest } from "@jest/globals";
import { sendVerificationEmail } from "@/lib/email/send-verification";

// Mock nodemailer for testing
jest.mock("nodemailer", () => ({
  createTransporter: jest.fn(() => ({
    sendMail: jest.fn().mockResolvedValue({ messageId: "test-message-id" }),
    verify: jest.fn().mockResolvedValue(true),
  })),
}));

describe("Email Verification", () => {
  it("should send verification email successfully", async () => {
    const result = await sendVerificationEmail({
      to: "test@company.com",
      name: "Test User",
      verifyUrl: "https://app.com/verify?token=test-token",
    });

    expect(result.success).toBe(true);
    expect(result.messageId).toBe("test-message-id");
  });

  it("should generate proper verification email content", () => {
    const { html, text } = generateVerificationEmail({
      name: "John Doe",
      verifyUrl: "https://app.com/verify?token=abc123",
      companyName: "Test Company",
    });

    expect(html).toContain("John Doe");
    expect(html).toContain("https://app.com/verify?token=abc123");
    expect(text).toContain("John Doe");
    expect(text).toContain("https://app.com/verify?token=abc123");
  });
});
```

---

## 📋 **Best Practices**

### **✅ Do:**

- Use professional email templates with proper branding
- Include both HTML and text versions of emails
- Set appropriate email expiration times (24 hours recommended)
- Provide clear instructions and fallback options
- Log email sending for debugging and monitoring
- Use environment variables for email configuration
- Test email delivery in staging environment

### **❌ Don't:**

- Send emails from development environments to real users
- Store email credentials in source code
- Skip email verification in production
- Use generic or unprofessional email templates
- Forget to handle email sending failures gracefully
- Allow infinite verification attempts without rate limiting

---

## 🔗 **Related Documentation**

- **[Better Auth Setup](./better-auth-setup.md)** - Core authentication configuration
- **[Reset Password](./reset-password.md)** - Password reset email patterns
- **[Admin Plugin](./admin-plugin-patterns.md)** - Admin user management

This email verification system provides a professional, secure, and user-friendly experience for enterprise Next.js applications.
