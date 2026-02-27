# React Lua Getting Started Guide

React Lua is a Roblox-compatible port of Facebook's React UI library. It's maintained by Roblox and used internally in the Roblox Universal App. This guide covers the essentials to get started.

## Key Differences from JavaScript React

| Feature | JavaScript React | React Lua |
|---------|------------------|-----------|
| **Syntax** | `const [value, setValue] = React.useState(0)` | `local value, setValue = React.useState(0)` |
| **JSX** | Supported | Not supported (use `React.createElement` instead) |
| **Rendering** | Concurrent Mode optional | Concurrent Mode enabled by default |
| **Version** | Latest (18+) | Aligned to React 17.0.1 |

## Basic Setup

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Shared.Packages.react)
local ReactRoblox = require(ReplicatedStorage.Shared.Packages["react-roblox"])

-- Create a simple component
local function MyFrame()
    return React.createElement("Frame", {
        Size = UDim2.new(0, 100, 0, 100),
        BackgroundColor3 = Color3.fromRGB(255, 194, 132),
    })
end

-- Mount to the screen
local handle = Instance.new("ScreenGui", game:GetService("Players").LocalPlayer.PlayerGui)
local root = ReactRoblox.createRoot(handle)
root:render(React.createElement(MyFrame, {}, {}))
```

## Core Concepts

### Components
Components are functions that return UI elements using `React.createElement`. Always return a single root element.

```lua
local function Button(props)
    return React.createElement("TextButton", {
        Size = UDim2.new(0, 100, 0, 50),
        Text = props.Text,
        [React.Event.Activated] = props.OnClick,
    })
end
```

### State - `useState`
Manage component state with the `useState` hook:

```lua
local function Counter()
    local count, setCount = React.useState(0)
    
    return React.createElement("TextLabel", {
        Size = UDim2.new(0, 100, 0, 100),
        Text = "Clicks: " .. tostring(count),
        [React.Event.Activated] = function()
            setCount(count + 1)
        end,
    })
end
```

### Effects - `useEffect`
Connect to events or external systems with `useEffect`. Always provide a dependency array:

```lua
local function Clock()
    local time, setTime = React.useState("")
    
    React.useEffect(function()
        local connection = game:GetService("RunService").Heartbeat:Connect(function()
            setTime(os.date("%X"))
        end)
        
        return function()
            connection:Disconnect()
        end
    end, {}) -- Empty array = run once on mount
    
    return React.createElement("TextLabel", {
        Size = UDim2.new(0, 200, 0, 100),
        Text = time,
    })
end
```

### Memoization - `useMemo`
Optimize expensive computations:

```lua
local function ExpensiveComponent(props)
    local result = React.useMemo(function()
        -- This only runs when props.data changes
        return computeExpensiveValue(props.data)
    end, {props.data})
    
    return React.createElement("TextLabel", {Text = tostring(result)})
end
```

## Common Patterns

### Passing Data Down (Props)
Components receive configuration through props:

```lua
local function Greeting(props)
    return React.createElement("TextLabel", {
        Text = "Hello, " .. props.Name .. "!",
    })
end

root:render(React.createElement(Greeting, {Name = "World"}))
```

### Callbacks from Child to Parent
Pass callbacks as props to communicate upward:

```lua
local function ChildButton(props)
    return React.createElement("TextButton", {
        Text = props.Label,
        [React.Event.Activated] = function()
            props.OnClick("child clicked")
        end,
    })
end

local function Parent()
    return React.createElement(ChildButton, {
        Label = "Click me",
        OnClick = function(message)
            print(message)
        end,
    })
end
```

## Styling with Roblox UIObjects

Use child UIObjects to style parent elements:

```lua
local function StyledFrame()
    return React.createElement("Frame", {
        Size = UDim2.new(0, 200, 0, 200),
        BackgroundColor3 = Color3.fromRGB(255, 194, 132),
    }, {
        Corner = React.createElement("UICorner", {
            CornerRadius = UDim.new(0, 20),
        }),
        Padding = React.createElement("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
        }),
        Content = React.createElement("TextLabel", {
            Text = "Styled Content",
            BackgroundTransparency = 1,
        }),
    })
end
```

## Type Safety with Luau

Add strict type checking to your components:

```lua
--!strict

export type ButtonProps = {
    Text: string,
    OnClick: () -> (),
    Disabled: boolean?,
}

local function TypedButton(props: ButtonProps)
    return React.createElement("TextButton", {
        Text = props.Text,
        [React.Event.Activated] = props.OnClick,
        Active = not (props.Disabled or false),
    })
end
```

## Important Notes

- **Always provide dependency arrays** to `useEffect` and `useMemo` (use `{}` for no dependencies)
- **Use `React.createElement`** instead of JSX (not yet supported)
- **Table state requires immutable updates**: rebuild tables when updating state
- **Breaking unidirectional flow**: `useRef` breaks the reactive paradigm; use sparingly
- **Functional components preferred**: Avoid class components unless necessary

## Resources

- [React JS Documentation](https://react.dev/) - Core concepts apply to React Lua
- [React Lua Documentation](https://react.luau.page/) - Lua-specific deviations
- [Roblox Developer Forum Guide](https://devforum.roblox.com/t/how-to-react-roblox/2964543) - Original tutorial
- [React Lua GitHub](https://github.com/jsdotlua/react-lua) - Source code and examples
