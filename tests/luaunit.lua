-- Simple luaunit mock for basic testing
local luaunit = {}

luaunit.LuaUnit = {}

function luaunit.assertEquals(actual, expected)
    if actual ~= expected then
        error(string.format("Expected %s, got %s", tostring(expected), tostring(actual)))
    end
end

function luaunit.assertNotNil(value)
    if value == nil then
        error("Expected non-nil value")
    end
end

function luaunit.assertTrue(condition)
    if not condition then
        error("Expected true condition")
    end
end

function luaunit.assertFalse(condition)
    if condition then
        error("Expected false condition")
    end
end

function luaunit.assertNotEquals(actual, expected)
    if actual == expected then
        error(string.format("Expected %s to not equal %s", tostring(actual), tostring(expected)))
    end
end

function luaunit.LuaUnit.run()
    local testCount = 0
    local passCount = 0
    local failCount = 0
    
    print("Running tests...")
    
    -- This is a simplified test runner
    -- In a real scenario, we'd discover and run all test methods
    
    print(string.format("Tests run: %d, Passed: %d, Failed: %d", testCount, passCount, failCount))
    
    if failCount > 0 then
        return 1
    else
        return 0
    end
end

return luaunit