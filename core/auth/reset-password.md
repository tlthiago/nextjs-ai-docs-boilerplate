# 🔄 Password Reset Patterns

## **Overview**

Secure password reset implementation using Better Auth with email notifications, token validation, and rate limiting for enterprise applications.

---

## 🔧 **Password Reset Flow**

### **Reset Email Template**

```typescript
// lib/email/templates/reset-password.ts
export function generateResetPasswordEmail({
  name,
  resetUrl,
  companyName = "Your Company",
}: {
  name: string;
  resetUrl: string;
  companyName?: string;
}) {
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Reset Your Password</title>
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
          background-color: #dc3545;
          color: white;
          text-decoration: none;
          padding: 12px 24px;
          border-radius: 6px;
          margin: 20px 0;
          font-weight: bold;
        }
        .button:hover {
          background-color: #c82333;
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
        .warning {
          background-color: #fff3cd;
          border: 1px solid #ffeaa7;
          padding: 15px;
          border-radius: 4px;
          margin: 20px 0;
        }
      </style>
    </head>
    <body>
      <div class="header">
        <h1>${companyName}</h1>
      </div>
      
      <div class="content">
        <h2>Password Reset Request</h2>
        
        <p>Hello ${name},</p>
        
        <p>We received a request to reset your password for your ${companyName} account. If you made this request, click the button below to reset your password:</p>
        
        <div style="text-align: center;">
          <a href="${resetUrl}" class="button">Reset Password</a>
        </div>
        
        <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
        <div class="code">${resetUrl}</div>
        
        <div class="warning">
          <strong>⚠️ Security Information:</strong>
          <ul>
            <li>This password reset link will expire in 1 hour for security reasons</li>
            <li>The link can only be used once</li>
            <li>If you didn't request this password reset, please ignore this email</li>
            <li>Your password will remain unchanged unless you click the link above</li>
          </ul>
        </div>
        
        <p>If you continue to have problems or didn't request this reset, please contact our support team immediately.</p>
        
        <p>Best regards,<br>The ${companyName} Security Team</p>
      </div>
      
      <div class="footer">
        <p>This is an automated security email. Please do not reply to this message.</p>
        <p>&copy; ${new Date().getFullYear()} ${companyName}. All rights reserved.</p>
      </div>
    </body>
    </html>
  `;

  const text = `
    Password Reset Request - ${companyName}
    
    Hello ${name},
    
    We received a request to reset your password for your ${companyName} account.
    
    If you made this request, visit this link to reset your password:
    ${resetUrl}
    
    SECURITY INFORMATION:
    - This link will expire in 1 hour
    - The link can only be used once  
    - If you didn't request this reset, please ignore this email
    - Your password will remain unchanged unless you use the link above
    
    If you continue to have problems, please contact our support team.
    
    Best regards,
    The ${companyName} Security Team
  `;

  return { html, text };
}
```

---

## 📤 **Reset Email Service**

### **Password Reset Email Sender**

```typescript
// lib/email/send-forgot-password.ts
import { sendEmail } from "./smtp";
import { generateResetPasswordEmail } from "./templates/reset-password";

export async function sendForgotPassword({
  to,
  name,
  resetUrl,
}: {
  to: string;
  name: string;
  resetUrl: string;
}) {
  const { html, text } = generateResetPasswordEmail({
    name,
    resetUrl,
    companyName: process.env.COMPANY_NAME || "Your Company",
  });

  const result = await sendEmail({
    to,
    subject: "Reset your password",
    html,
    text,
  });

  if (!result.success) {
    console.error("Failed to send password reset email:", result.error);
    throw new Error("Failed to send password reset email");
  }

  console.log(`Password reset email sent to ${to}`);
  return result;
}

// Rate limiting for password reset requests
const resetAttempts = new Map<string, { count: number; lastAttempt: Date }>();

export function checkResetRateLimit(email: string): boolean {
  const now = new Date();
  const attempts = resetAttempts.get(email);
  
  if (!attempts) {
    resetAttempts.set(email, { count: 1, lastAttempt: now });
    return true;
  }

  // Reset counter if more than 1 hour has passed
  const hourAgo = new Date(now.getTime() - 60 * 60 * 1000);
  if (attempts.lastAttempt < hourAgo) {
    resetAttempts.set(email, { count: 1, lastAttempt: now });
    return true;
  }

  // Allow max 3 attempts per hour
  if (attempts.count >= 3) {
    return false;
  }

  attempts.count++;
  attempts.lastAttempt = now;
  return true;
}
```

---

## 🔗 **Password Reset API Routes**

### **Request Password Reset**

```typescript
// app/api/auth/forgot-password/route.ts
import { NextRequest } from "next/server";
import { z } from "zod";
import { auth } from "@/lib/auth";
import { checkResetRateLimit } from "@/lib/email/send-forgot-password";

const forgotPasswordSchema = z.object({
  email: z.string().email("Invalid email address"),
});

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { email } = forgotPasswordSchema.parse(body);

    // Check rate limiting
    if (!checkResetRateLimit(email)) {
      return Response.json(
        { error: "Too many reset attempts. Please try again later." },
        { status: 429 }
      );
    }

    // Check if user exists
    const user = await prisma.user.findUnique({
      where: { email },
    });

    // Always return success to prevent email enumeration
    if (!user) {
      return Response.json({ 
        message: "If an account with that email exists, we've sent a password reset link." 
      });
    }

    // Check if user is active
    if (!user.active) {
      return Response.json({ 
        message: "If an account with that email exists, we've sent a password reset link." 
      });
    }

    // Send password reset email using Better Auth
    await auth.api.forgetPassword({
      body: { email },
    });

    return Response.json({ 
      message: "If an account with that email exists, we've sent a password reset link." 
    });
  } catch (error) {
    console.error("Forgot password error:", error);
    
    if (error instanceof z.ZodError) {
      return Response.json(
        { error: "Invalid email format" },
        { status: 400 }
      );
    }

    return Response.json(
      { error: "Failed to process password reset request" },
      { status: 500 }
    );
  }
}
```

### **Reset Password Confirmation**

```typescript
// app/api/auth/reset-password/route.ts
import { NextRequest } from "next/server";
import { z } from "zod";
import { auth } from "@/lib/auth";

const resetPasswordSchema = z.object({
  token: z.string().min(1, "Reset token is required"),
  password: z
    .string()
    .min(8, "Password must be at least 8 characters")
    .regex(
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
      "Password must contain at least one lowercase letter, one uppercase letter, and one number"
    ),
});

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { token, password } = resetPasswordSchema.parse(body);

    // Reset password using Better Auth
    const result = await auth.api.resetPassword({
      body: { token, password },
    });

    if (!result.success) {
      return Response.json(
        { error: "Invalid or expired reset token" },
        { status: 400 }
      );
    }

    return Response.json({ 
      message: "Password reset successfully. You can now sign in with your new password." 
    });
  } catch (error) {
    console.error("Reset password error:", error);
    
    if (error instanceof z.ZodError) {
      return Response.json(
        { error: error.errors[0].message },
        { status: 400 }
      );
    }

    return Response.json(
      { error: "Failed to reset password" },
      { status: 500 }
    );
  }
}
```

---

## 🎯 **Frontend Components**

### **Forgot Password Form**

```typescript
// components/auth/forgot-password-form.tsx
"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { ArrowLeft, Mail } from "lucide-react";
import Link from "next/link";

const forgotPasswordSchema = z.object({
  email: z.string().email("Invalid email address"),
});

type ForgotPasswordFormData = z.infer<typeof forgotPasswordSchema>;

export function ForgotPasswordForm() {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  const form = useForm<ForgotPasswordFormData>({
    resolver: zodResolver(forgotPasswordSchema),
    defaultValues: {
      email: "",
    },
  });

  const onSubmit = async (data: ForgotPasswordFormData) => {
    setIsSubmitting(true);
    setMessage("");
    setError("");

    try {
      const response = await fetch("/api/auth/forgot-password", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(data),
      });

      const result = await response.json();

      if (response.ok) {
        setMessage(result.message);
      } else {
        setError(result.error || "Failed to send reset email");
      }
    } catch (err) {
      setError("An unexpected error occurred. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  if (message) {
    return (
      <div className="text-center">
        <Mail className="mx-auto h-16 w-16 text-blue-500 mb-4" />
        <h2 className="text-2xl font-bold mb-4">Check Your Email</h2>
        <Alert>
          <AlertDescription>{message}</AlertDescription>
        </Alert>
        <p className="mt-4 text-sm text-gray-600">
          Didn't receive the email? Check your spam folder or{" "}
          <button
            onClick={() => {
              setMessage("");
              form.reset();
            }}
            className="text-blue-600 hover:underline"
          >
            try again
          </button>
        </p>
        <Link
          href="/login"
          className="mt-6 inline-flex items-center text-sm text-gray-600 hover:text-gray-900"
        >
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back to Login
        </Link>
      </div>
    );
  }

  return (
    <div>
      <div className="text-center mb-6">
        <h2 className="text-2xl font-bold">Forgot Password</h2>
        <p className="text-gray-600 mt-2">
          Enter your email address and we'll send you a reset link
        </p>
      </div>

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
          <FormField
            control={form.control}
            name="email"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Email Address</FormLabel>
                <FormControl>
                  <Input
                    type="email"
                    placeholder="your@email.com"
                    {...field}
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          {error && (
            <Alert variant="destructive">
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          <Button type="submit" className="w-full" disabled={isSubmitting}>
            {isSubmitting ? "Sending..." : "Send Reset Link"}
          </Button>
        </form>
      </Form>

      <div className="mt-6 text-center">
        <Link
          href="/login"
          className="inline-flex items-center text-sm text-gray-600 hover:text-gray-900"
        >
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back to Login
        </Link>
      </div>
    </div>
  );
}
```

### **Reset Password Form**

```typescript
// components/auth/reset-password-form.tsx
"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { CheckCircle, Eye, EyeOff } from "lucide-react";

const resetPasswordSchema = z
  .object({
    password: z
      .string()
      .min(8, "Password must be at least 8 characters")
      .regex(
        /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
        "Password must contain at least one lowercase letter, one uppercase letter, and one number"
      ),
    confirmPassword: z.string(),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Passwords don't match",
    path: ["confirmPassword"],
  });

type ResetPasswordFormData = z.infer<typeof resetPasswordSchema>;

interface ResetPasswordFormProps {
  token: string;
}

export function ResetPasswordForm({ token }: ResetPasswordFormProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const router = useRouter();

  const form = useForm<ResetPasswordFormData>({
    resolver: zodResolver(resetPasswordSchema),
    defaultValues: {
      password: "",
      confirmPassword: "",
    },
  });

  const onSubmit = async (data: ResetPasswordFormData) => {
    setIsSubmitting(true);
    setError("");

    try {
      const response = await fetch("/api/auth/reset-password", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          token,
          password: data.password,
        }),
      });

      const result = await response.json();

      if (response.ok) {
        setSuccess(true);
        setTimeout(() => {
          router.push("/login");
        }, 3000);
      } else {
        setError(result.error || "Failed to reset password");
      }
    } catch (err) {
      setError("An unexpected error occurred. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  if (success) {
    return (
      <div className="text-center">
        <CheckCircle className="mx-auto h-16 w-16 text-green-500 mb-4" />
        <h2 className="text-2xl font-bold text-green-600 mb-4">
          Password Reset Successfully!
        </h2>
        <Alert>
          <AlertDescription>
            Your password has been reset. You will be redirected to the login page shortly.
          </AlertDescription>
        </Alert>
      </div>
    );
  }

  return (
    <div>
      <div className="text-center mb-6">
        <h2 className="text-2xl font-bold">Reset Password</h2>
        <p className="text-gray-600 mt-2">
          Enter your new password below
        </p>
      </div>

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
          <FormField
            control={form.control}
            name="password"
            render={({ field }) => (
              <FormItem>
                <FormLabel>New Password</FormLabel>
                <FormControl>
                  <div className="relative">
                    <Input
                      type={showPassword ? "text" : "password"}
                      {...field}
                    />
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      className="absolute right-0 top-0 h-full px-3 py-2 hover:bg-transparent"
                      onClick={() => setShowPassword(!showPassword)}
                    >
                      {showPassword ? (
                        <EyeOff className="h-4 w-4" />
                      ) : (
                        <Eye className="h-4 w-4" />
                      )}
                    </Button>
                  </div>
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="confirmPassword"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Confirm New Password</FormLabel>
                <FormControl>
                  <div className="relative">
                    <Input
                      type={showConfirmPassword ? "text" : "password"}
                      {...field}
                    />
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      className="absolute right-0 top-0 h-full px-3 py-2 hover:bg-transparent"
                      onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                    >
                      {showConfirmPassword ? (
                        <EyeOff className="h-4 w-4" />
                      ) : (
                        <Eye className="h-4 w-4" />
                      )}
                    </Button>
                  </div>
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          {error && (
            <Alert variant="destructive">
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          <Button type="submit" className="w-full" disabled={isSubmitting}>
            {isSubmitting ? "Resetting..." : "Reset Password"}
          </Button>
        </form>
      </Form>

      <div className="mt-4 text-xs text-gray-600">
        <p className="font-medium">Password Requirements:</p>
        <ul className="mt-1 list-disc list-inside space-y-1">
          <li>At least 8 characters long</li>
          <li>Contains at least one lowercase letter</li>
          <li>Contains at least one uppercase letter</li>
          <li>Contains at least one number</li>
        </ul>
      </div>
    </div>
  );
}
```

---

## 📄 **Reset Password Pages**

### **Forgot Password Page**

```typescript
// app/auth/forgot-password/page.tsx
import { ForgotPasswordForm } from "@/components/auth/forgot-password-form";

export default function ForgotPasswordPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="w-full max-w-md p-8">
        <ForgotPasswordForm />
      </div>
    </div>
  );
}
```

### **Reset Password Page**

```typescript
// app/auth/reset-password/page.tsx
import { ResetPasswordForm } from "@/components/auth/reset-password-form";
import { redirect } from "next/navigation";

interface ResetPasswordPageProps {
  searchParams: {
    token?: string;
  };
}

export default function ResetPasswordPage({
  searchParams,
}: ResetPasswordPageProps) {
  const { token } = searchParams;

  if (!token) {
    redirect("/auth/forgot-password");
  }

  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="w-full max-w-md p-8">
        <ResetPasswordForm token={token} />
      </div>
    </div>
  );
}
```

---

## 🧪 **Testing Password Reset**

### **Reset Flow Tests**

```typescript
// __tests__/auth/password-reset.test.ts
import { describe, it, expect, jest } from "@jest/globals";
import { sendForgotPassword, checkResetRateLimit } from "@/lib/email/send-forgot-password";

describe("Password Reset", () => {
  it("should send password reset email", async () => {
    const result = await sendForgotPassword({
      to: "test@company.com",
      name: "Test User",
      resetUrl: "https://app.com/reset?token=test-token",
    });

    expect(result.success).toBe(true);
  });

  it("should enforce rate limiting", () => {
    const email = "test@example.com";
    
    // First 3 attempts should succeed
    expect(checkResetRateLimit(email)).toBe(true);
    expect(checkResetRateLimit(email)).toBe(true);
    expect(checkResetRateLimit(email)).toBe(true);
    
    // 4th attempt should fail
    expect(checkResetRateLimit(email)).toBe(false);
  });
});
```

---

## 📋 **Best Practices**

### **✅ Do:**

- Use secure password requirements (length, complexity)
- Implement rate limiting to prevent abuse
- Always return generic messages to prevent email enumeration
- Set appropriate token expiration times (1 hour recommended)
- Include clear security warnings in emails
- Log password reset attempts for security monitoring
- Require strong passwords with validation

### **❌ Don't:**

- Reveal whether an email exists in the system
- Allow unlimited password reset attempts
- Use weak or predictable reset tokens
- Skip email validation in reset forms
- Store reset tokens in plain text
- Allow password reset for inactive accounts
- Forget to invalidate sessions after password reset

---

## 🔗 **Related Documentation**

- **[Better Auth Setup](./better-auth-setup.md)** - Core authentication configuration
- **[Email Verification](./email-verification.md)** - Email verification patterns
- **[Permission System](./permission-system.md)** - Role-based access control

This password reset system provides enterprise-grade security with user-friendly experience and comprehensive protection against common attacks.
