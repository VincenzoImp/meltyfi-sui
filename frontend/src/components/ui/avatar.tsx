import { cn } from "@/lib/utils"
import * as AvatarPrimitive from "@radix-ui/react-avatar"
import { cva, type VariantProps } from "class-variance-authority"
import * as React from "react"

const avatarVariants = cva(
    "relative flex shrink-0 overflow-hidden rounded-full",
    {
        variants: {
            size: {
                sm: "h-8 w-8",
                default: "h-10 w-10",
                lg: "h-12 w-12",
                xl: "h-16 w-16",
                "2xl": "h-20 w-20",
            },
        },
        defaultVariants: {
            size: "default",
        },
    }
)

const Avatar = React.forwardRef<
    React.ElementRef<typeof AvatarPrimitive.Root>,
    React.ComponentPropsWithoutRef<typeof AvatarPrimitive.Root> &
    VariantProps<typeof avatarVariants>
>(({ className, size, ...props }, ref) => (
    <AvatarPrimitive.Root
        ref={ref}
        className={cn(avatarVariants({ size }), className)}
        {...props}
    />
))
Avatar.displayName = AvatarPrimitive.Root.displayName

const AvatarImage = React.forwardRef<
    React.ElementRef<typeof AvatarPrimitive.Image>,
    React.ComponentPropsWithoutRef<typeof AvatarPrimitive.Image>
>(({ className, ...props }, ref) => (
    <AvatarPrimitive.Image
        ref={ref}
        className={cn("aspect-square h-full w-full", className)}
        {...props}
    />
))
AvatarImage.displayName = AvatarPrimitive.Image.displayName

const AvatarFallback = React.forwardRef<
    React.ElementRef<typeof AvatarPrimitive.Fallback>,
    React.ComponentPropsWithoutRef<typeof AvatarPrimitive.Fallback>
>(({ className, ...props }, ref) => (
    <AvatarPrimitive.Fallback
        ref={ref}
        className={cn(
            "flex h-full w-full items-center justify-center rounded-full bg-muted",
            className
        )}
        {...props}
    />
))
AvatarFallback.displayName = AvatarPrimitive.Fallback.displayName

// User Avatar with initials
interface UserAvatarProps extends React.ComponentPropsWithoutRef<typeof Avatar> {
    src?: string
    name?: string
    size?: VariantProps<typeof avatarVariants>['size']
}

const UserAvatar = React.forwardRef<
    React.ElementRef<typeof Avatar>,
    UserAvatarProps
>(({ src, name, size, className, ...props }, ref) => {
    const getInitials = (name?: string) => {
        if (!name) return "?"
        return name
            .split(" ")
            .map((n) => n[0])
            .join("")
            .toUpperCase()
            .slice(0, 2)
    }

    return (
        <Avatar ref={ref} size={size} className={className} {...props}>
            <AvatarImage src={src} alt={name} />
            <AvatarFallback>{getInitials(name)}</AvatarFallback>
        </Avatar>
    )
})
UserAvatar.displayName = "UserAvatar"

// Avatar Group
interface AvatarGroupProps extends React.HTMLAttributes<HTMLDivElement> {
    limit?: number
    total?: number
    size?: VariantProps<typeof avatarVariants>['size']
    children: React.ReactElement<UserAvatarProps>[]
}

const AvatarGroup = React.forwardRef<HTMLDivElement, AvatarGroupProps>(
    ({ className, children, limit = 3, total, size = "default", ...props }, ref) => {
        const avatarsToShow = children.slice(0, limit)
        const remainingCount = total ? total - limit : children.length - limit

        return (
            <div
                ref={ref}
                className={cn("flex -space-x-2", className)}
                {...props}
            >
                {avatarsToShow.map((avatar, index) =>
                    React.cloneElement(avatar, {
                        key: index,
                        size,
                        className: cn(
                            "border-2 border-background",
                            avatar.props.className
                        ),
                    })
                )}
                {remainingCount > 0 && (
                    <Avatar size={size} className="border-2 border-background">
                        <AvatarFallback className="bg-muted-foreground text-muted">
                            +{remainingCount}
                        </AvatarFallback>
                    </Avatar>
                )}
            </div>
        )
    }
)
AvatarGroup.displayName = "AvatarGroup"

// Status Avatar - with online indicator
interface StatusAvatarProps extends UserAvatarProps {
    status?: 'online' | 'offline' | 'away' | 'busy'
    showStatus?: boolean
}

const StatusAvatar = React.forwardRef<
    React.ElementRef<typeof Avatar>,
    StatusAvatarProps
>(({ status = 'offline', showStatus = true, className, ...props }, ref) => {
    const statusColors = {
        online: 'bg-green-500',
        offline: 'bg-gray-400',
        away: 'bg-yellow-500',
        busy: 'bg-red-500'
    }

    return (
        <div className="relative">
            <UserAvatar ref={ref} className={className} {...props} />
            {showStatus && (
                <div
                    className={cn(
                        "absolute bottom-0 right-0 h-3 w-3 rounded-full border-2 border-background",
                        statusColors[status]
                    )}
                />
            )}
        </div>
    )
})
StatusAvatar.displayName = "StatusAvatar"

export {
    Avatar, AvatarFallback, AvatarGroup, AvatarImage, avatarVariants, StatusAvatar, UserAvatar
}
