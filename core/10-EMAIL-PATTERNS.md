# 📧 Email Communication Patterns

## **Overview**

This project uses **Nodemailer** with **React Email** for transactional email communication, providing type-safe templates and reliable delivery.

> 💡 **Why React Email**: Write emails using React components with proper TypeScript support and preview functionality.

---

## 🔧 **Email Infrastructure Setup**

### **Nodemailer Configuration**

```typescript
// lib/email.ts
import nodemailer from "nodemailer";
import { render } from "@react-email/render";

const transporter = nodemailer.createTransporter({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT || "587"),
  secure: process.env.SMTP_SECURE === "true",
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASSWORD,
  },
});

export interface EmailOptions {
  to: string | string[];
  subject: string;
  template: React.ComponentType<any>;
  templateProps?: Record<string, any>;
  from?: string;
}

export async function sendEmail({
  to,
  subject,
  template: Template,
  templateProps = {},
  from = process.env.SMTP_FROM,
}: EmailOptions) {
  try {
    const html = render(<Template {...templateProps} />);
    const text = render(<Template {...templateProps} />, { plainText: true });

    const result = await transporter.sendMail({
      from,
      to: Array.isArray(to) ? to.join(", ") : to,
      subject,
      html,
      text,
    });

    return { success: true, messageId: result.messageId };
  } catch (error) {
    console.error("Email sending failed:", error);
    return { success: false, error: error.message };
  }
}

export async function verifyEmailConnection() {
  try {
    await transporter.verify();
    return true;
  } catch (error) {
    console.error("Email connection failed:", error);
    return false;
  }
}
```

### **Environment Variables**

```bash
# .env.local
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM="Your App <noreply@yourapp.com>"
```

---

## 📨 **Email Templates**

### **Base Email Layout**

```typescript
// emails/components/layout.tsx
import {
  Html,
  Head,
  Body,
  Container,
  Section,
  Img,
  Text,
  Hr,
} from "@react-email/components";

interface EmailLayoutProps {
  children: React.ReactNode;
  title?: string;
}

export function EmailLayout({ children, title }: EmailLayoutProps) {
  return (
    <Html>
      <Head>
        <title>{title}</title>
      </Head>
      <Body style={main}>
        <Container style={container}>
          <Section style={header}>
            <Img
              src="https://yourapp.com/logo.png"
              width="150"
              height="50"
              alt="Your App"
              style={logo}
            />
          </Section>

          <Section style={content}>{children}</Section>

          <Hr style={divider} />

          <Section style={footer}>
            <Text style={footerText}>
              © 2024 Your App. All rights reserved.
            </Text>
            <Text style={footerText}>
              If you didn't request this email, you can safely ignore it.
            </Text>
          </Section>
        </Container>
      </Body>
    </Html>
  );
}

const main = {
  backgroundColor: "#f6f9fc",
  fontFamily:
    '-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Ubuntu,sans-serif',
};

const container = {
  backgroundColor: "#ffffff",
  margin: "0 auto",
  padding: "20px 0 48px",
  marginBottom: "64px",
  maxWidth: "600px",
};

const header = {
  padding: "20px 30px",
};

const logo = {
  margin: "0 auto",
};

const content = {
  padding: "0 30px",
};

const divider = {
  borderColor: "#e6ebf1",
  margin: "20px 0",
};

const footer = {
  padding: "0 30px",
};

const footerText = {
  color: "#8898aa",
  fontSize: "12px",
  lineHeight: "16px",
};
```

### **Welcome Email Template**

```typescript
// emails/welcome.tsx
import { EmailLayout } from "./components/layout";
import { Text, Button, Section } from "@react-email/components";

interface WelcomeEmailProps {
  userName: string;
  loginUrl: string;
}

export function WelcomeEmail({ userName, loginUrl }: WelcomeEmailProps) {
  return (
    <EmailLayout title="Welcome to Your App">
      <Text style={heading}>Welcome to Your App!</Text>

      <Text style={paragraph}>Hi {userName},</Text>

      <Text style={paragraph}>
        Thank you for signing up! We're excited to have you on board. Your
        account has been successfully created and you can now access all the
        features of our platform.
      </Text>

      <Section style={buttonContainer}>
        <Button style={button} href={loginUrl}>
          Get Started
        </Button>
      </Section>

      <Text style={paragraph}>
        If you have any questions, feel free to reply to this email. Our team is
        here to help!
      </Text>

      <Text style={paragraph}>
        Best regards,
        <br />
        The Your App Team
      </Text>
    </EmailLayout>
  );
}

const heading = {
  fontSize: "24px",
  fontWeight: "bold",
  color: "#333333",
  marginBottom: "20px",
};

const paragraph = {
  fontSize: "16px",
  lineHeight: "26px",
  color: "#555555",
  marginBottom: "16px",
};

const buttonContainer = {
  textAlign: "center" as const,
  margin: "32px 0",
};

const button = {
  backgroundColor: "#007ee6",
  borderRadius: "4px",
  color: "#fff",
  fontSize: "16px",
  textDecoration: "none",
  textAlign: "center" as const,
  display: "block",
  padding: "12px 20px",
  fontWeight: "bold",
};
```

### **Email Verification Template**

```typescript
// emails/verify-email.tsx
import { EmailLayout } from "./components/layout";
import { Text, Button, Section, Code } from "@react-email/components";

interface VerifyEmailProps {
  userName: string;
  verificationUrl: string;
  verificationCode: string;
}

export function VerifyEmail({
  userName,
  verificationUrl,
  verificationCode,
}: VerifyEmailProps) {
  return (
    <EmailLayout title="Verify Your Email">
      <Text style={heading}>Verify Your Email Address</Text>

      <Text style={paragraph}>Hi {userName},</Text>

      <Text style={paragraph}>
        Please verify your email address by clicking the button below or
        entering the verification code in the app.
      </Text>

      <Section style={buttonContainer}>
        <Button style={button} href={verificationUrl}>
          Verify Email Address
        </Button>
      </Section>

      <Text style={paragraph}>
        Alternatively, you can use this verification code:
      </Text>

      <Code style={code}>{verificationCode}</Code>

      <Text style={paragraph}>
        This verification link will expire in 24 hours for security reasons.
      </Text>

      <Text style={paragraph}>
        If you didn't create an account, you can safely ignore this email.
      </Text>
    </EmailLayout>
  );
}

const heading = {
  fontSize: "24px",
  fontWeight: "bold",
  color: "#333333",
  marginBottom: "20px",
};

const paragraph = {
  fontSize: "16px",
  lineHeight: "26px",
  color: "#555555",
  marginBottom: "16px",
};

const buttonContainer = {
  textAlign: "center" as const,
  margin: "32px 0",
};

const button = {
  backgroundColor: "#007ee6",
  borderRadius: "4px",
  color: "#fff",
  fontSize: "16px",
  textDecoration: "none",
  textAlign: "center" as const,
  display: "block",
  padding: "12px 20px",
  fontWeight: "bold",
};

const code = {
  display: "inline-block",
  padding: "16px 4.5%",
  width: "90.5%",
  backgroundColor: "#f4f4f4",
  borderRadius: "5px",
  border: "1px solid #eee",
  color: "#333",
  fontSize: "18px",
  fontFamily: "monospace",
  textAlign: "center" as const,
  margin: "16px 0",
};
```

### **Password Reset Template**

```typescript
// emails/password-reset.tsx
import { EmailLayout } from "./components/layout";
import { Text, Button, Section } from "@react-email/components";

interface PasswordResetProps {
  userName: string;
  resetUrl: string;
}

export function PasswordReset({ userName, resetUrl }: PasswordResetProps) {
  return (
    <EmailLayout title="Reset Your Password">
      <Text style={heading}>Reset Your Password</Text>

      <Text style={paragraph}>Hi {userName},</Text>

      <Text style={paragraph}>
        You recently requested to reset your password. Click the button below to
        create a new password:
      </Text>

      <Section style={buttonContainer}>
        <Button style={button} href={resetUrl}>
          Reset Password
        </Button>
      </Section>

      <Text style={paragraph}>
        This password reset link will expire in 1 hour for security reasons.
      </Text>

      <Text style={paragraph}>
        If you didn't request a password reset, you can safely ignore this
        email. Your password will remain unchanged.
      </Text>

      <Text style={paragraph}>
        For security reasons, this link can only be used once.
      </Text>
    </EmailLayout>
  );
}

const heading = {
  fontSize: "24px",
  fontWeight: "bold",
  color: "#333333",
  marginBottom: "20px",
};

const paragraph = {
  fontSize: "16px",
  lineHeight: "26px",
  color: "#555555",
  marginBottom: "16px",
};

const buttonContainer = {
  textAlign: "center" as const,
  margin: "32px 0",
};

const button = {
  backgroundColor: "#dc2626",
  borderRadius: "4px",
  color: "#fff",
  fontSize: "16px",
  textDecoration: "none",
  textAlign: "center" as const,
  display: "block",
  padding: "12px 20px",
  fontWeight: "bold",
};
```

---

## 🎯 **Email Service Patterns**

### **Email Service Class**

```typescript
// services/email-service.ts
import { sendEmail } from "@/lib/email";
import { WelcomeEmail } from "@/emails/welcome";
import { VerifyEmail } from "@/emails/verify-email";
import { PasswordReset } from "@/emails/password-reset";

export class EmailService {
  private baseUrl: string;

  constructor() {
    this.baseUrl = process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000";
  }

  async sendWelcomeEmail(to: string, userName: string) {
    return sendEmail({
      to,
      subject: "Welcome to Your App!",
      template: WelcomeEmail,
      templateProps: {
        userName,
        loginUrl: `${this.baseUrl}/login`,
      },
    });
  }

  async sendVerificationEmail(
    to: string,
    userName: string,
    verificationToken: string,
    verificationCode: string
  ) {
    return sendEmail({
      to,
      subject: "Verify Your Email Address",
      template: VerifyEmail,
      templateProps: {
        userName,
        verificationUrl: `${this.baseUrl}/verify-email?token=${verificationToken}`,
        verificationCode,
      },
    });
  }

  async sendPasswordResetEmail(
    to: string,
    userName: string,
    resetToken: string
  ) {
    return sendEmail({
      to,
      subject: "Reset Your Password",
      template: PasswordReset,
      templateProps: {
        userName,
        resetUrl: `${this.baseUrl}/reset-password?token=${resetToken}`,
      },
    });
  }

  async sendNotificationEmail(to: string, subject: string, message: string) {
    return sendEmail({
      to,
      subject,
      template: ({ message }: { message: string }) => (
        <EmailLayout title={subject}>
          <Text
            style={{ fontSize: "16px", lineHeight: "26px", color: "#555555" }}
          >
            {message}
          </Text>
        </EmailLayout>
      ),
      templateProps: { message },
    });
  }
}

export const emailService = new EmailService();
```

### **Email Queue Pattern (Optional)**

```typescript
// lib/email-queue.ts
interface EmailJob {
  id: string;
  to: string;
  subject: string;
  template: string;
  templateProps: Record<string, any>;
  attempts: number;
  maxAttempts: number;
  scheduledAt: Date;
  createdAt: Date;
}

export class EmailQueue {
  private queue: EmailJob[] = [];
  private processing = false;

  async addJob(
    to: string,
    subject: string,
    template: string,
    templateProps: Record<string, any>,
    delay = 0
  ) {
    const job: EmailJob = {
      id: crypto.randomUUID(),
      to,
      subject,
      template,
      templateProps,
      attempts: 0,
      maxAttempts: 3,
      scheduledAt: new Date(Date.now() + delay),
      createdAt: new Date(),
    };

    this.queue.push(job);

    if (!this.processing) {
      this.processQueue();
    }

    return job.id;
  }

  private async processQueue() {
    this.processing = true;

    while (this.queue.length > 0) {
      const now = new Date();
      const readyJobs = this.queue.filter((job) => job.scheduledAt <= now);

      if (readyJobs.length === 0) {
        await new Promise((resolve) => setTimeout(resolve, 1000));
        continue;
      }

      const job = readyJobs[0];

      try {
        // Process email job
        await this.processEmailJob(job);
        this.removeJob(job.id);
      } catch (error) {
        job.attempts++;

        if (job.attempts >= job.maxAttempts) {
          console.error(
            `Email job ${job.id} failed after ${job.maxAttempts} attempts:`,
            error
          );
          this.removeJob(job.id);
        } else {
          // Exponential backoff
          job.scheduledAt = new Date(
            Date.now() + Math.pow(2, job.attempts) * 1000
          );
        }
      }
    }

    this.processing = false;
  }

  private async processEmailJob(job: EmailJob) {
    // Implementation depends on your email templates
    // This is a simplified version
    console.log(`Processing email job: ${job.id}`);
  }

  private removeJob(id: string) {
    this.queue = this.queue.filter((job) => job.id !== id);
  }
}

export const emailQueue = new EmailQueue();
```

---

## 🔗 **Integration Patterns**

### **Authentication Integration**

```typescript
// app/api/auth/register/route.ts
import { NextRequest } from "next/server";
import { emailService } from "@/services/email-service";
import { auth } from "@/lib/auth";

export async function POST(req: NextRequest) {
  try {
    const { email, password, name } = await req.json();

    // Create user account
    const user = await auth.signUp.email({
      email,
      password,
      name,
    });

    // Send welcome email
    await emailService.sendWelcomeEmail(email, name);

    // Send verification email if required
    if (user.emailVerified === false) {
      const verificationToken = await auth.generateVerificationToken(user.id);
      const verificationCode = Math.random().toString().substring(2, 8);

      await emailService.sendVerificationEmail(
        email,
        name,
        verificationToken,
        verificationCode
      );
    }

    return Response.json({ success: true });
  } catch (error) {
    return Response.json({ error: error.message }, { status: 400 });
  }
}
```

### **Form Integration**

```typescript
// components/contact-form.tsx
"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";

const contactSchema = z.object({
  name: z.string().min(2, "Name must be at least 2 characters"),
  email: z.string().email("Invalid email address"),
  message: z.string().min(10, "Message must be at least 10 characters"),
});

type ContactFormData = z.infer<typeof contactSchema>;

export function ContactForm() {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSubmitted, setIsSubmitted] = useState(false);

  const form = useForm<ContactFormData>({
    resolver: zodResolver(contactSchema),
  });

  const onSubmit = async (data: ContactFormData) => {
    setIsSubmitting(true);

    try {
      const response = await fetch("/api/contact", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });

      if (response.ok) {
        setIsSubmitted(true);
        form.reset();
      } else {
        throw new Error("Failed to send message");
      }
    } catch (error) {
      form.setError("root", {
        message: "Failed to send message. Please try again.",
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isSubmitted) {
    return (
      <div className="text-center p-6 border border-green-200 bg-green-50 rounded-lg">
        <h3 className="text-lg font-semibold text-green-800">Message Sent!</h3>
        <p className="text-green-600">We'll get back to you soon.</p>
      </div>
    );
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
      {/* Form fields implementation */}
    </form>
  );
}
```

---

## 🧪 **Testing Email Templates**

### **Preview Development Server**

```typescript
// scripts/email-preview.ts
import { render } from "@react-email/render";
import { WelcomeEmail } from "../emails/welcome";
import { VerifyEmail } from "../emails/verify-email";
import { PasswordReset } from "../emails/password-reset";

// Preview emails in development
export function previewEmails() {
  const welcomeHtml = render(
    <WelcomeEmail userName="John Doe" loginUrl="http://localhost:3000/login" />
  );

  const verifyHtml = render(
    <VerifyEmail
      userName="John Doe"
      verificationUrl="http://localhost:3000/verify?token=abc123"
      verificationCode="123456"
    />
  );

  const resetHtml = render(
    <PasswordReset
      userName="John Doe"
      resetUrl="http://localhost:3000/reset?token=abc123"
    />
  );

  console.log("Email previews generated");
  return { welcomeHtml, verifyHtml, resetHtml };
}
```

### **Email Testing**

```typescript
// __tests__/services/email-service.test.ts
import { describe, it, expect, jest, beforeEach } from "@jest/globals";
import { EmailService } from "@/services/email-service";
import * as emailLib from "@/lib/email";

// Mock the email library
jest.mock("@/lib/email");
const mockSendEmail = jest.mocked(emailLib.sendEmail);

describe("EmailService", () => {
  let emailService: EmailService;

  beforeEach(() => {
    emailService = new EmailService();
    jest.clearAllMocks();
  });

  it("should send welcome email with correct parameters", async () => {
    mockSendEmail.mockResolvedValue({ success: true, messageId: "123" });

    await emailService.sendWelcomeEmail("test@example.com", "John Doe");

    expect(mockSendEmail).toHaveBeenCalledWith({
      to: "test@example.com",
      subject: "Welcome to Your App!",
      template: expect.any(Function),
      templateProps: {
        userName: "John Doe",
        loginUrl: expect.stringContaining("/login"),
      },
    });
  });

  it("should handle email sending failures", async () => {
    mockSendEmail.mockResolvedValue({ success: false, error: "SMTP error" });

    const result = await emailService.sendWelcomeEmail(
      "test@example.com",
      "John Doe"
    );

    expect(result.success).toBe(false);
    expect(result.error).toBe("SMTP error");
  });
});
```

---

## 📋 **Best Practices**

### **✅ Do:**

- Use React Email for type-safe templates
- Implement email verification for new accounts
- Include both HTML and plain text versions
- Test email templates in different clients
- Use environment variables for SMTP configuration
- Implement email delivery error handling
- Add unsubscribe links where required

### **❌ Don't:**

- Send emails synchronously in API responses
- Hardcode email addresses or content
- Skip email validation before sending
- Use inline CSS for complex layouts
- Forget about mobile email clients
- Send emails without proper error handling
- Include sensitive data in email URLs

---

## 🔗 **Integration with Other Patterns**

- **Authentication**: Send verification and password reset emails
- **API Patterns**: Use proper error handling for email failures
- **Service Patterns**: Encapsulate email logic in services
- **Testing**: Mock email sending in tests
- **Error Handling**: Handle SMTP failures gracefully

This email system provides reliable transactional email capabilities while maintaining developer productivity and AI agent compatibility.
