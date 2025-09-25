import { cn } from "@/lib/utils"
import { cva, type VariantProps } from "class-variance-authority"
import * as React from "react"

const cardVariants = cva(
    "rounded-xl border bg-card text-card-foreground shadow",
    {
        variants: {
            variant: {
                default: "border-border",
                elevated: "shadow-lg",
                interactive: "transition-all hover:shadow-md hover:-translate-y-0.5 cursor-pointer",
                outline: "border-2",
            },
        },
        defaultVariants: {
            variant: "default",
        },
    }
)

export interface CardProps
    extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof cardVariants> { }

const Card = React.forwardRef<HTMLDivElement, CardProps>(
    ({ className, variant, ...props }, ref) => (
        <div
            ref={ref}
            className={cn(cardVariants({ variant }), className)}
            {...props}
        />
    )
)
Card.displayName = "Card"

const CardHeader = React.forwardRef<
    HTMLDivElement,
    React.HTMLAttributes<HTMLDivElement> & {
        centered?: boolean
    }
>(({ className, centered = false, ...props }, ref) => (
    <div
        ref={ref}
        className={cn(
            "flex flex-col space-y-1.5 p-6",
            centered && "text-center items-center",
            className
        )}
        {...props}
    />
))
CardHeader.displayName = "CardHeader"

const CardTitle = React.forwardRef<
    HTMLDivElement,
    React.HTMLAttributes<HTMLDivElement> & {
        as?: 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6'
    }
>(({ className, as: Comp = 'h3', children, ...props }, ref) => (
    <Comp
        ref={ref}
        className={cn("font-semibold leading-none tracking-tight", className)}
        {...props}
    >
        {children}
    </Comp>
))
CardTitle.displayName = "CardTitle"

const CardDescription = React.forwardRef<
    HTMLParagraphElement,
    React.HTMLAttributes<HTMLParagraphElement>
>(({ className, ...props }, ref) => (
    <p
        ref={ref}
        className={cn("text-sm text-muted-foreground", className)}
        {...props}
    />
))
CardDescription.displayName = "CardDescription"

const CardContent = React.forwardRef<
    HTMLDivElement,
    React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
    <div ref={ref} className={cn("p-6 pt-0", className)} {...props} />
))
CardContent.displayName = "CardContent"

const CardFooter = React.forwardRef<
    HTMLDivElement,
    React.HTMLAttributes<HTMLDivElement> & {
        centered?: boolean
    }
>(({ className, centered = false, ...props }, ref) => (
    <div
        ref={ref}
        className={cn(
            "flex items-center p-6 pt-0",
            centered ? "justify-center" : "justify-between",
            className
        )}
        {...props}
    />
))
CardFooter.displayName = "CardFooter"

// Specialized Card Components
const StatsCard = React.forwardRef<
    HTMLDivElement,
    React.HTMLAttributes<HTMLDivElement> & {
        title: string
        value: string | number
        change?: string
        changeType?: 'positive' | 'negative' | 'neutral'
        icon?: React.ReactNode
    }
>(({ className, title, value, change, changeType = 'neutral', icon, ...props }, ref) => (
    <Card
        ref={ref}
        variant="elevated"
        className={cn("relative overflow-hidden", className)}
        {...props}
    >
        <CardContent className="p-6">
            <div className="flex items-center justify-between">
                <div className="space-y-2">
                    <p className="text-sm font-medium text-muted-foreground">
                        {title}
                    </p>
                    <div className="flex items-baseline space-x-2">
                        <h3 className="text-2xl font-bold tracking-tight">
                            {value}
                        </h3>
                        {change && (
                            <span className={cn(
                                "text-sm font-medium",
                                changeType === 'positive' && "text-green-600 dark:text-green-500",
                                changeType === 'negative' && "text-red-600 dark:text-red-500",
                                changeType === 'neutral' && "text-muted-foreground"
                            )}>
                                {change}
                            </span>
                        )}
                    </div>
                </div>
                {icon && (
                    <div className="text-muted-foreground opacity-80">
                        {icon}
                    </div>
                )}
            </div>
        </CardContent>
    </Card>
))
StatsCard.displayName = "StatsCard"

const FeatureCard = React.forwardRef<
    HTMLDivElement,
    React.HTMLAttributes<HTMLDivElement> & {
        title: string
        description: string
        icon?: React.ReactNode
        href?: string
    }
>(({ className, title, description, icon, href, ...props }, ref) => {
    const CardComponent = href ? 'a' : 'div'

    return (
        <Card
            ref={ref}
            variant={href ? "interactive" : "elevated"}
            className={cn("group h-full", className)}
            {...props}
        >
            {href ? (
                <CardComponent href={href} className="block h-full">
                    <CardContent className="p-6 flex flex-col h-full">
                        <div className="space-y-4 flex-1">
                            {icon && (
                                <div className="text-primary group-hover:scale-105 transition-transform duration-200 w-fit">
                                    {icon}
                                </div>
                            )}
                            <div className="space-y-2">
                                <h3 className="font-semibold text-lg group-hover:text-primary transition-colors">
                                    {title}
                                </h3>
                                <p className="text-sm text-muted-foreground leading-relaxed">
                                    {description}
                                </p>
                            </div>
                        </div>
                    </CardContent>
                </CardComponent>
            ) : (
                <CardContent className="p-6 flex flex-col h-full">
                    <div className="space-y-4 flex-1">
                        {icon && (
                            <div className="text-primary w-fit">
                                {icon}
                            </div>
                        )}
                        <div className="space-y-2">
                            <h3 className="font-semibold text-lg">
                                {title}
                            </h3>
                            <p className="text-sm text-muted-foreground leading-relaxed">
                                {description}
                            </p>
                        </div>
                    </div>
                </CardContent>
            )}
        </Card>
    )
})
FeatureCard.displayName = "FeatureCard"

const LoadingCard = React.forwardRef<
    HTMLDivElement,
    React.HTMLAttributes<HTMLDivElement> & {
        lines?: number
    }
>(({ className, lines = 3, ...props }, ref) => (
    <Card
        ref={ref}
        className={cn("animate-pulse", className)}
        {...props}
    >
        <CardContent className="p-6">
            <div className="space-y-4">
                <div className="h-4 bg-muted rounded w-1/4"></div>
                {Array.from({ length: lines }).map((_, i) => (
                    <div
                        key={i}
                        className={cn(
                            "h-3 bg-muted rounded",
                            i === lines - 1 ? "w-2/3" : "w-full"
                        )}
                    />
                ))}
            </div>
        </CardContent>
    </Card>
))
LoadingCard.displayName = "LoadingCard"

export {
    Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle, cardVariants, FeatureCard,
    LoadingCard, StatsCard
}
