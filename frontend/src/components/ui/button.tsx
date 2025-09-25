import { cn } from "@/lib/utils"
import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"
import { Loader2 } from "lucide-react"
import * as React from "react"

const buttonVariants = cva(
    "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0",
    {
        variants: {
            variant: {
                default:
                    "bg-primary text-primary-foreground shadow hover:bg-primary/90",
                destructive:
                    "bg-destructive text-destructive-foreground shadow-sm hover:bg-destructive/90",
                outline:
                    "border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground",
                secondary:
                    "bg-secondary text-secondary-foreground shadow-sm hover:bg-secondary/80",
                ghost: "hover:bg-accent hover:text-accent-foreground",
                link: "text-primary underline-offset-4 hover:underline",
            },
            size: {
                default: "h-9 px-4 py-2",
                sm: "h-8 rounded-md px-3 text-xs",
                lg: "h-10 rounded-md px-8",
                icon: "h-9 w-9",
            },
        },
        defaultVariants: {
            variant: "default",
            size: "default",
        },
    }
)

export interface ButtonProps
    extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
    asChild?: boolean
    loading?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
    ({ className, variant, size, asChild = false, loading = false, disabled, children, ...props }, ref) => {
        const Comp = asChild ? Slot : "button"
        const isDisabled = disabled || loading

        return (
            <Comp
                className={cn(buttonVariants({ variant, size, className }))}
                ref={ref}
                disabled={isDisabled}
                {...props}
            >
                {loading && <Loader2 className="h-4 w-4 animate-spin" />}
                {children}
            </Comp>
        )
    }
)
Button.displayName = "Button"

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
                    orientation === 'horizontal'
                        ? "flex-row [&>*:not(:first-child):not(:last-child)]:rounded-none [&>*:first-child]:rounded-r-none [&>*:last-child]:rounded-l-none [&>*:not(:first-child)]:border-l-0"
                        : "flex-col [&>*:not(:first-child):not(:last-child)]:rounded-none [&>*:first-child]:rounded-b-none [&>*:last-child]:rounded-t-none [&>*:not(:first-child)]:border-t-0",
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

// Loading button variant
const LoadingButton = React.forwardRef<HTMLButtonElement, ButtonProps>(
    (props, ref) => <Button ref={ref} loading {...props} />
)
LoadingButton.displayName = "LoadingButton"

export { Button, ButtonGroup, buttonVariants, LoadingButton }
