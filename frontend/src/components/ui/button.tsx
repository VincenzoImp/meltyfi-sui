import { cn } from "@/lib/utils"
import { cva, type VariantProps } from "class-variance-authority"
import { Loader2 } from "lucide-react"
import * as React from "react"

const buttonVariants = cva(
    [
        "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-lg text-sm font-medium",
        "ring-offset-background transition-all duration-200 focus-visible:outline-none focus-visible:ring-2",
        "focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
        "active:scale-[0.98] transform-gpu"
    ].join(" "),
    {
        variants: {
            variant: {
                default: [
                    "bg-gradient-to-r from-primary to-melty-gold-500 text-primary-foreground",
                    "shadow-lg hover:shadow-xl hover:shadow-primary/25",
                    "hover:from-primary/90 hover:to-melty-gold-500/90",
                    "border border-primary/20"
                ].join(" "),
                destructive: [
                    "bg-destructive text-destructive-foreground shadow-md",
                    "hover:bg-destructive/90 hover:shadow-lg hover:shadow-destructive/25"
                ].join(" "),
                outline: [
                    "border-2 border-primary bg-transparent text-primary shadow-sm",
                    "hover:bg-primary hover:text-primary-foreground",
                    "hover:shadow-md hover:shadow-primary/20"
                ].join(" "),
                secondary: [
                    "bg-secondary text-secondary-foreground shadow-sm",
                    "hover:bg-secondary/80 hover:shadow-md"
                ].join(" "),
                ghost: [
                    "text-primary hover:bg-primary/10 hover:text-primary",
                    "hover:shadow-sm"
                ].join(" "),
                link: [
                    "text-primary underline-offset-4 hover:underline",
                    "hover:text-primary/80"
                ].join(" "),
                gradient: [
                    "bg-gradient-to-r from-melty-purple-500 to-melty-chocolate-500",
                    "text-white shadow-lg hover:shadow-xl",
                    "hover:shadow-melty-purple-500/25 hover:from-melty-purple-600",
                    "hover:to-melty-chocolate-600"
                ].join(" "),
                glass: [
                    "bg-white/10 backdrop-blur-md border border-white/20",
                    "text-foreground shadow-lg hover:bg-white/20",
                    "hover:shadow-xl hover:shadow-white/10"
                ].join(" "),
                success: [
                    "bg-success text-success-foreground shadow-md",
                    "hover:bg-success/90 hover:shadow-lg hover:shadow-success/25"
                ].join(" "),
                warning: [
                    "bg-warning text-warning-foreground shadow-md",
                    "hover:bg-warning/90 hover:shadow-lg hover:shadow-warning/25"
                ].join(" "),
                info: [
                    "bg-info text-info-foreground shadow-md",
                    "hover:bg-info/90 hover:shadow-lg hover:shadow-info/25"
                ].join(" "),
            },
            size: {
                default: "h-10 px-4 py-2",
                sm: "h-9 rounded-md px-3 text-xs",
                lg: "h-12 rounded-lg px-8 text-base",
                xl: "h-14 rounded-xl px-10 text-lg",
                icon: "h-10 w-10",
                "icon-sm": "h-8 w-8",
                "icon-lg": "h-12 w-12",
            },
            loading: {
                true: "cursor-not-allowed",
                false: "",
            },
        },
        defaultVariants: {
            variant: "default",
            size: "default",
            loading: false,
        },
    }
)

export interface ButtonProps
    extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
    loading?: boolean
    leftIcon?: React.ReactNode
    rightIcon?: React.ReactNode
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
    ({
        className,
        variant,
        size,
        loading = false,
        leftIcon,
        rightIcon,
        children,
        disabled,
        ...props
    }, ref) => {
        const isDisabled = disabled || loading

        return (
            <button
                className={cn(buttonVariants({ variant, size, loading, className }))}
                ref={ref}
                disabled={isDisabled}
                {...props}
            >
                {loading && (
                    <Loader2 className="h-4 w-4 animate-spin" />
                )}

                {!loading && leftIcon && (
                    <span className="shrink-0">
                        {leftIcon}
                    </span>
                )}

                {children && (
                    <span className={cn(
                        "truncate",
                        loading && "ml-2"
                    )}>
                        {children}
                    </span>
                )}

                {!loading && rightIcon && (
                    <span className="shrink-0">
                        {rightIcon}
                    </span>
                )}
            </button>
        )
    }
)
Button.displayName = "Button"

// Specialized button components
const GradientButton = React.forwardRef<HTMLButtonElement, ButtonProps>(
    (props, ref) => <Button ref={ref} variant="gradient" {...props} />
)
GradientButton.displayName = "GradientButton"

const GlassButton = React.forwardRef<HTMLButtonElement, ButtonProps>(
    (props, ref) => <Button ref={ref} variant="glass" {...props} />
)
GlassButton.displayName = "GlassButton"

const IconButton = React.forwardRef<
    HTMLButtonElement,
    ButtonProps & { icon: React.ReactNode }
>(({ icon, children, ...props }, ref) => (
    <Button ref={ref} size="icon" {...props}>
        {icon}
        {children && <span className="sr-only">{children}</span>}
    </Button>
))
IconButton.displayName = "IconButton"

// Button group component
interface ButtonGroupProps extends React.HTMLAttributes<HTMLDivElement> {
    orientation?: 'horizontal' | 'vertical'
    size?: VariantProps<typeof buttonVariants>['size']
}

const ButtonGroup = React.forwardRef<HTMLDivElement, ButtonGroupProps>(
    ({ className, orientation = 'horizontal', children, ...props }, ref) => {
        return (
            <div
                ref={ref}
                className={cn(
                    "inline-flex",
                    orientation === 'horizontal' ? "flex-row" : "flex-col",
                    "[&>button]:rounded-none",
                    "[&>button:first-child]:rounded-l-lg",
                    "[&>button:last-child]:rounded-r-lg",
                    orientation === 'vertical' && [
                        "[&>button:first-child]:rounded-t-lg [&>button:first-child]:rounded-l-none",
                        "[&>button:last-child]:rounded-b-lg [&>button:last-child]:rounded-r-none"
                    ],
                    "[&>button:not(:first-child)]:border-l-0",
                    orientation === 'vertical' && "[&>button:not(:first-child)]:border-l [&>button:not(:first-child)]:border-t-0",
                    className
                )}
                {...props}
            >
                {children}
            </div>
        )
    }
)
ButtonGroup.displayName = "ButtonGroup"

export {
    Button, ButtonGroup, buttonVariants, GlassButton, GradientButton, IconButton
}
