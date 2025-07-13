#!/usr/bin/env lua

-- Terminal Drift Dedicated Server Startup Script
-- This script runs the server independently of LÖVE2D

-- Add source directory to path
package.path = package.path .. ";src/?.lua"

local Server = require("server")

-- Create and run server
local server = Server:new(7777)

-- Handle command line arguments
if arg[1] then
    local port = tonumber(arg[1])
    if port then
        server.port = port
        print("Using custom port: " .. port)
    end
end

-- Run the server
local exitCode = server:run()
os.exit(exitCode)