import { cn } from "@/lib/utils"
import { cva, type VariantProps } from "class-variance-authority"
import * as React from "react"

const cardVariants = cva(
    [
        "rounded-xl border bg-card text-card-foreground shadow-sm transition-all duration-200",
        "hover:shadow-md"
    ].join(" "),
    {
        variants: {
            variant: {
                default: "border-border bg-card",
                elevated: [
                    "shadow-lg hover:shadow-xl",
                    "bg-gradient-to-br from-card to-card/95"
                ].join(" "),
                glass: [
                    "bg-white/5 backdrop-blur-md border-white/10",
                    "shadow-lg hover:bg-white/10",
                    "dark:bg-black/5 dark:border-white/5"
                ].join(" "),
                gradient: [
                    "bg-gradient-to-br from-melty-chocolate-50 to-melty-gold-50",
                    "border-melty-chocolate-200/50 shadow-md hover:shadow-lg",
                    "dark:from-melty-chocolate-900/20 dark:to-melty-gold-900/20",
                    "dark:border-melty-chocolate-800/50"
                ].join(" "),
                outline: [
                    "border-2 border-primary/20 bg-transparent",
                    "hover:border-primary/40 hover:bg-primary/5"
                ].join(" "),
                interactive: [
                    "cursor-pointer hover:shadow-lg active:scale-[0.98]",
                    "transform-gpu hover:-translate-y-1",
                    "border-border/50 hover:border-primary/30"
                ].join(" "),
            },
            size: {
                sm: "p-4",
                default: "p-6",
                lg: "p-8",
                xl: "p-10",
            },
        },
        defaultVariants: {
            variant: "default",
            size: "default",
        },
    }
)

const Card = React.forwardRef<
    HTMLDivElement,
    React.HTMLAttributes<HTMLDivElement> & VariantProps<typeof cardVariants>
>(({ className, variant, size, ...props }, ref) => (
    <div
        ref={ref}
        className={cn(cardVariants({ variant, size }), className)}
        {...props}
    />
))
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
            "flex flex-col space-y-1.5 pb-6",
            centered && "text-center",
            className
        )}
        {...props}
    />
))
CardHeader.displayName = "CardHeader"

const CardTitle = React.forwardRef<
    HTMLHeadingElement,
    React.HTMLAttributes<HTMLHeadingElement> & {
        as?: 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6'
        gradient?: boolean
    }
>(({ className, as: Comp = 'h3', gradient = false, children, ...props }, ref) => (
    <Comp
        ref={ref}
        className={cn(
            "text-2xl font-semibold leading-none tracking-tight",
            gradient && [
                "bg-gradient-to-r from-primary to-melty-gold-500",
                "bg-clip-text text-transparent"
            ],
            className
        )}
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
        className={cn("text-sm text-muted-foreground leading-relaxed", className)}
        {...props}
    />
))
CardDescription.displayName = "CardDescription"

const CardContent = React.forwardRef<
    HTMLDivElement,
    React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
    <div
        ref={ref}
        className={cn("pt-0", className)}
        {...props}
    />
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
            "flex items-center pt-6",
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
                        <h3 className="text-3xl font-bold tracking-tight">
                            {value}
                        </h3>
                        {change && (
                            <span className={cn(
                                "text-sm font-medium",
                                changeType === 'positive' && "text-success",
                                changeType === 'negative' && "text-destructive",
                                changeType === 'neutral' && "text-muted-foreground"
                            )}>
                                {change}
                            </span>
                        )}
                    </div>
                </div>
                {icon && (
                    <div className="text-muted-foreground">
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
    const Comp = href ? 'a' : 'div'

    return (
        <Card
            ref={ref}
            variant={href ? "interactive" : "elevated"}
            className={cn("group", className)}
            {...props}
        >
            {href ? (
                <a href={href} className="block">
                    <CardContent>
                        <div className="space-y-4">
                            {icon && (
                                <div className="text-primary group-hover:scale-110 transition-transform duration-200">
                                    {icon}
                                </div>
                            )}
                            <div className="space-y-2">
                                <h3 className="font-semibold group-hover:text-primary transition-colors">
                                    {title}
                                </h3>
                                <p className="text-sm text-muted-foreground leading-relaxed">
                                    {description}
                                </p>
                            </div>
                        </div>
                    </CardContent>
                </a>
            ) : (
                <CardContent>
                    <div className="space-y-4">
                        {icon && (
                            <div className="text-primary">
                                {icon}
                            </div>
                        )}
                        <div className="space-y-2">
                            <h3 className="font-semibold">
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
        <CardContent>
            <div className="space-y-4">
                <div className="h-4 bg-muted rounded w-1/3" />
                {Array.from({ length: lines }).map((_, i) => (
                    <div
                        key={i}
                        className="h-3 bg-muted rounded"
                        style={{ width: `${Math.random() * 40 + 60}%` }}
                    />
                ))}
            </div>
        </CardContent>
    </Card>
))
LoadingCard.displayName = "LoadingCard"

export {
    Card,
    CardContent,
    CardDescription,
    CardFooter,
    CardHeader,
    CardTitle, cardVariants, FeatureCard,
    LoadingCard, StatsCard
}
