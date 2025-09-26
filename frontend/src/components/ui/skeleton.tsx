import { cn } from "@/lib/utils"
import * as React from "react"

function Skeleton({
    className,
    ...props
}: React.HTMLAttributes<HTMLDivElement>) {
    return (
        <div
            className={cn("animate-pulse rounded-md bg-primary/10", className)}
            {...props}
        />
    )
}

// Text Skeleton - for text content
interface TextSkeletonProps extends React.HTMLAttributes<HTMLDivElement> {
    lines?: number
    lastLineWidth?: string
}

const TextSkeleton = React.forwardRef<HTMLDivElement, TextSkeletonProps>(
    ({ className, lines = 1, lastLineWidth = "60%", ...props }, ref) => {
        return (
            <div ref={ref} className={cn("space-y-2", className)} {...props}>
                {Array.from({ length: lines }).map((_, i) => (
                    <Skeleton
                        key={i}
                        className={cn(
                            "h-4",
                            i === lines - 1 ? `w-[${lastLineWidth}]` : "w-full"
                        )}
                    />
                ))}
            </div>
        )
    }
)
TextSkeleton.displayName = "TextSkeleton"

// Card Skeleton - for card layouts
interface CardSkeletonProps extends React.HTMLAttributes<HTMLDivElement> {
    showAvatar?: boolean
    showImage?: boolean
    lines?: number
}

const CardSkeleton = React.forwardRef<HTMLDivElement, CardSkeletonProps>(
    ({ className, showAvatar = false, showImage = false, lines = 3, ...props }, ref) => {
        return (
            <div
                ref={ref}
                className={cn("p-6 space-y-4 border rounded-lg", className)}
                {...props}
            >
                {showImage && <Skeleton className="h-48 w-full" />}

                <div className="space-y-4">
                    {showAvatar && (
                        <div className="flex items-center space-x-4">
                            <Skeleton className="h-12 w-12 rounded-full" />
                            <div className="space-y-2 flex-1">
                                <Skeleton className="h-4 w-1/4" />
                                <Skeleton className="h-4 w-1/6" />
                            </div>
                        </div>
                    )}

                    <div className="space-y-2">
                        <Skeleton className="h-4 w-1/3" />
                        <TextSkeleton lines={lines} />
                    </div>
                </div>
            </div>
        )
    }
)
CardSkeleton.displayName = "CardSkeleton"

// Table Skeleton - for table layouts
interface TableSkeletonProps extends React.HTMLAttributes<HTMLDivElement> {
    rows?: number
    columns?: number
}

const TableSkeleton = React.forwardRef<HTMLDivElement, TableSkeletonProps>(
    ({ className, rows = 5, columns = 4, ...props }, ref) => {
        return (
            <div ref={ref} className={cn("space-y-3", className)} {...props}>
                {/* Header */}
                <div className="flex space-x-4">
                    {Array.from({ length: columns }).map((_, i) => (
                        <Skeleton key={`header-${i}`} className="h-4 flex-1" />
                    ))}
                </div>

                {/* Rows */}
                {Array.from({ length: rows }).map((_, rowIndex) => (
                    <div key={`row-${rowIndex}`} className="flex space-x-4">
                        {Array.from({ length: columns }).map((_, colIndex) => (
                            <Skeleton
                                key={`cell-${rowIndex}-${colIndex}`}
                                className={cn(
                                    "h-4 flex-1",
                                    colIndex === 0 && "w-16", // First column smaller
                                )}
                            />
                        ))}
                    </div>
                ))}
            </div>
        )
    }
)
TableSkeleton.displayName = "TableSkeleton"

// List Skeleton - for list layouts
interface ListSkeletonProps extends React.HTMLAttributes<HTMLDivElement> {
    items?: number
    showAvatar?: boolean
}

const ListSkeleton = React.forwardRef<HTMLDivElement, ListSkeletonProps>(
    ({ className, items = 5, showAvatar = false, ...props }, ref) => {
        return (
            <div ref={ref} className={cn("space-y-4", className)} {...props}>
                {Array.from({ length: items }).map((_, i) => (
                    <div key={i} className="flex items-center space-x-4">
                        {showAvatar && <Skeleton className="h-10 w-10 rounded-full" />}
                        <div className="space-y-2 flex-1">
                            <Skeleton className="h-4 w-3/4" />
                            <Skeleton className="h-4 w-1/2" />
                        </div>
                    </div>
                ))}
            </div>
        )
    }
)
ListSkeleton.displayName = "ListSkeleton"

// Button Skeleton
interface ButtonSkeletonProps extends React.HTMLAttributes<HTMLDivElement> {
    size?: 'sm' | 'default' | 'lg'
}

const ButtonSkeleton = React.forwardRef<HTMLDivElement, ButtonSkeletonProps>(
    ({ className, size = 'default', ...props }, ref) => {
        const sizeClasses = {
            sm: 'h-8 w-20',
            default: 'h-9 w-24',
            lg: 'h-10 w-28'
        }

        return (
            <Skeleton
                ref={ref}
                className={cn("rounded-md", sizeClasses[size], className)}
                {...props}
            />
        )
    }
)
ButtonSkeleton.displayName = "ButtonSkeleton"

// Avatar Skeleton
interface AvatarSkeletonProps extends React.HTMLAttributes<HTMLDivElement> {
    size?: 'sm' | 'default' | 'lg' | 'xl'
}

const AvatarSkeleton = React.forwardRef<HTMLDivElement, AvatarSkeletonProps>(
    ({ className, size = 'default', ...props }, ref) => {
        const sizeClasses = {
            sm: 'h-8 w-8',
            default: 'h-10 w-10',
            lg: 'h-12 w-12',
            xl: 'h-16 w-16'
        }

        return (
            <Skeleton
                ref={ref}
                className={cn("rounded-full", sizeClasses[size], className)}
                {...props}
            />
        )
    }
)
AvatarSkeleton.displayName = "AvatarSkeleton"

// Form Skeleton - for form layouts
interface FormSkeletonProps extends React.HTMLAttributes<HTMLDivElement> {
    fields?: number
}

const FormSkeleton = React.forwardRef<HTMLDivElement, FormSkeletonProps>(
    ({ className, fields = 4, ...props }, ref) => {
        return (
            <div ref={ref} className={cn("space-y-6", className)} {...props}>
                {Array.from({ length: fields }).map((_, i) => (
                    <div key={i} className="space-y-2">
                        <Skeleton className="h-4 w-24" />
                        <Skeleton className="h-9 w-full" />
                    </div>
                ))}
                <div className="flex space-x-2 pt-4">
                    <ButtonSkeleton />
                    <ButtonSkeleton />
                </div>
            </div>
        )
    }
)
FormSkeleton.displayName = "FormSkeleton"

export {
    AvatarSkeleton, ButtonSkeleton, CardSkeleton, FormSkeleton, ListSkeleton, Skeleton, TableSkeleton, TextSkeleton
}
