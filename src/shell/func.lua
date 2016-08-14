local ffi = require 'ffi'
local lucy = ffi.load("lucy")
local noncanon = require 'lucy.noncanon'

function EXIT(code)
    noncanon.toggle()
    os.exit(code or 0)
end

function string.trim(s)
  return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function RUN_CODE_LOCALLY(code)
    local callback = function(message)
        return debug.traceback(message, 2)
    end
    local f, err = load(code)
    if not f then
        return 'ERROR: '..err
    else
        local success, result = xpcall(f, callback)
        if not success then
            result = 'ERROR: '..result
        end
        return tostring(result)
    end
end

function run_command()
    if command == "exit" then
        EXIT()
    end
    local result
    if #string.trim(command) > 0 then
        result = RUN_CODE(command)
        local ret = 'return '
        if string.sub(command, 1, #ret) == ret and not result then
            result = 'nil'
        end
        if result then
            PRINT_RESULT(string.gsub(string.gsub(result, '\n\t', '\n    '), '\n', '\n      '))
        else
            result = nil
        end
        table.insert(history, command)
    end
    history_idx = nil
    PROMPT(result or false)
end


function PRINT_RESULT(result)
    local comp = "ERROR: "
    PRINT("      ")
    if string.sub(result, 1, #comp) == comp then
        RED_PRINT(result)
    else
        GREEN_PRINT(result)
    end
end

function PRINT(str)
    ffi.C.write(STDOUT_FD, str, #str)
end

function CURSOR_RIGHT(n)
    if n == 0 then return end
    PRINT("\x1B["..n.."C")
end

function CURSOR_LEFT(n)
    if n == 0 then return end
    PRINT("\x1B["..n.."D")
end

function MAGENTA_PRINT(str)
    PRINT("\x1B[1;34m")
    PRINT(str)
    PRINT("\x1B[0m")
end

function BACKSPACE(n)
    for i=1,n do
        PRINT("\b \b")
    end
end

function BELL()
    PRINT("\a")
end

function GREEN_PRINT(str)
    PRINT("\x1B[1;32m")
    PRINT(str)
    PRINT("\x1B[0m")
end

function RED_PRINT(str)
    PRINT("\x1B[1;31m")
    PRINT(str)
    PRINT("\x1B[0m")
end

prompt_text = "\x1B[1;31m".."l".."\x1B[33m".."u".."\x1B[32m".."c".."\x1B[34m".."y".."\x1B[35m".."#".."\x1B[0m "
function PROMPT(newline)
    if newline == nil then newline = true end

    command = ""
    if newline then
        PRINT('\n')
    end
    PRINT(prompt_text)
    cursor_pos = 1
end

function PRINT_BUFFER(count)
    for i=0,count-1 do
        local c = buffer[i]
        if ffi.C.isprint(c) then
            local s = string.char(c)
            if cursor_pos == #command + 1 then
                PRINT(s)
                command = command..s
            else
                local tail = s..string.sub(command, cursor_pos, #command)
                command = string.sub(command, 1, cursor_pos - 1)..tail
                PRINT(tail)
                CURSOR_LEFT(#tail - 1)
            end
            cursor_pos = cursor_pos + 1
        end
    end
end
