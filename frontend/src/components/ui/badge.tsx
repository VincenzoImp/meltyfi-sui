import { cn } from "@/lib/utils"
import { cva, type VariantProps } from "class-variance-authority"
import * as React from "react"

const badgeVariants = cva(
    "inline-flex items-center rounded-md border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
    {
        variants: {
            variant: {
                default:
                    "border-transparent bg-primary text-primary-foreground shadow hover:bg-primary/80",
                secondary:
                    "border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80",
                destructive:
                    "border-transparent bg-destructive text-destructive-foreground shadow hover:bg-destructive/80",
                outline: "text-foreground",
                success:
                    "border-transparent bg-green-500 text-white shadow hover:bg-green-500/80",
                warning:
                    "border-transparent bg-yellow-500 text-white shadow hover:bg-yellow-500/80",
                info:
                    "border-transparent bg-blue-500 text-white shadow hover:bg-blue-500/80",
            },
            size: {
                default: "px-2.5 py-0.5 text-xs",
                sm: "px-2 py-0.5 text-xs",
                lg: "px-3 py-1 text-sm",
            }
        },
        defaultVariants: {
            variant: "default",
            size: "default",
        },
    }
)

export interface BadgeProps
    extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> { }

function Badge({ className, variant, size, ...props }: BadgeProps) {
    return (
        <div className={cn(badgeVariants({ variant, size }), className)} {...props} />
    )
}

// Status Badge - specialized variant for showing status
interface StatusBadgeProps extends BadgeProps {
    status: 'active' | 'inactive' | 'pending' | 'success' | 'error' | 'warning'
}

function StatusBadge({ status, className, ...props }: StatusBadgeProps) {
    const statusVariants = {
        active: "success",
        inactive: "secondary",
        pending: "warning",
        success: "success",
        error: "destructive",
        warning: "warning"
    } as const

    return (
        <Badge
            variant={statusVariants[status]}
            className={cn("capitalize", className)}
            {...props}
        >
            {status}
        </Badge>
    )
}

// Number Badge - for showing counts
interface NumberBadgeProps extends BadgeProps {
    count: number
    max?: number
    showZero?: boolean
}

function NumberBadge({ count, max = 99, showZero = false, className, ...props }: NumberBadgeProps) {
    if (count === 0 && !showZero) {
        return null
    }

    const displayCount = count > max ? `${max}+` : count.toString()

    return (
        <Badge
            variant="destructive"
            className={cn("h-5 min-w-[1.25rem] px-1 text-xs font-bold", className)}
            {...props}
        >
            {displayCount}
        </Badge>
    )
}

// Dot Badge - simple indicator
interface DotBadgeProps extends BadgeProps {
    color?: 'green' | 'red' | 'yellow' | 'blue' | 'gray'
}

function DotBadge({ color = 'gray', className, children, ...props }: DotBadgeProps) {
    const dotColors = {
        green: "bg-green-500",
        red: "bg-red-500",
        yellow: "bg-yellow-500",
        blue: "bg-blue-500",
        gray: "bg-gray-500"
    }

    return (
        <Badge
            variant="outline"
            className={cn("gap-1", className)}
            {...props}
        >
            <div className={cn("h-2 w-2 rounded-full", dotColors[color])} />
            {children}
        </Badge>
    )
}

export { Badge, badgeVariants, DotBadge, NumberBadge, StatusBadge }
