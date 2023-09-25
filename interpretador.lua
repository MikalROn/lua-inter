local cjson = require("cjson")

-- helpers
local function printTabela(tabela)
    for chave, valor in pairs(tabela) do
        print(chave, valor)
    end
end

local functions = {}
local counter = 1

Funcao = {}
Funcao.__index = Funcao

function Funcao.new(param, value, context)
    local self = setmetatable({}, Funcao)
    self.key = tostring(self)

    context[self.key] = {}

    for i, argument in ipairs(param) do
        context[self.key][i] = argument.text
    end

    self.values = value

    self.get_parameters = function () return context[self.key] end
    self.parameters = self.get_parameters()

    return self
end

function Funcao:call(arguments, context)
    local novo_contexto = {}
    for i, argument in ipairs(arguments) do
        local key = context[tostring(self)][i]
        novo_contexto[key] = interpreter(argument, context)
    end
    return interpreter(self.values, novo_contexto)
end


local operations = {
    Add = function(a, b)
        if type(a) == 'string' or type(b) == "string" then
            return a .. b
        end
        return a + b
    end,
    Sub = function(a, b) return a - b end,
    Mul = function(a, b) return a * b end,
    Div = function(a, b) return a / b end,
    Rem = function(a, b) return a % b end,
    Eq = function(a, b) return a == b end,
    Neq = function(a, b) return a ~= b end,
    Lt = function(a, b) return a < b end,
    Gt = function(a, b) return a > b end,
    Lte = function(a, b) return a <= b end,
    Gte = function(a, b) return a >= b end,
    And = function(a, b) return a and b end,
    Or = function(a, b) return a or b end
}

local Terms = {
    Int = function(expression, context)
        return expression.value
    end,
    Str = function(expression, context)
        return expression.value
    end,
    Bool = function(expression, context)
        return expression.value
    end,
    Var = function(expression, context)
        return context[expression.text]
    end,
    Tuple = function(expression, context)
        return {expression.value.first, expression.value.second}
    end,
    Binary = function(expression, context)
        for i, item in pairs(context) do
            print(i, item)
        end
        local a = interpreter(expression.lhs, context)
        local b = interpreter(expression.rhs, context)
        return operations[expression.op](a, b)
    end,
    Print = function(expression, context)
        local val = interpreter(expression.value, context)
        print(val)
        return val
    end,
    Let = function(expression, context)
        context[expression.name.text] = interpreter(expression.value, context)
        if expression.next ~= nil then
            return interpreter(expression.next, context)
        end
    end,
    Call = function(expression, context)
        return context[expression.callee.text]:call(expression.arguments, context)
    end,
    If = function(expression, context)
            if interpreter(expression.condition, context) then
                return  interpreter(expression['then'], context)
            else
                return  interpreter(expression.otherwise, context)
        end
    end,
    Function = function(expression, context)
        return Funcao.new(expression.parameters, expression.value, context)
    end,
    First = function(expression, context)
        local tuple = interpreter(expression.value, context)
        assert(type(tuple) == "table" and #tuple == 2, "Value is not a tuple!")
        return tuple[1]
    end,
    Second = function(expression, context)
        local tuple = interpreter(expression.value, context)
        assert(type(tuple) == "table" and #tuple == 2, "Value is not a tuple!")
        return tuple[2]
    end
}

function interpreter(expression, context)
    print(expression.kind)
    if Terms[expression.kind] ~= nil then
        return  Terms[expression.kind](expression, context)
    else
        error("Termo não existe ou não implementado -> "..expression.kind)
    end
end


function readFile(filepath)
    local file, error_message = io.open(filepath, "r")

    if not file then
        print("Erro ao abrir o arquivo: " .. error_message)
        return nil
    end

    local file_content = file:read("*a")

    file:close()

    local success, json_data = pcall(cjson.decode, file_content)

    if not success then
        print("Erro ao decodificar JSON: " .. json_data)
        return nil
    end

    return json_data
end



local data = readFile("var/rinha/source.rinha.json")

if data then
        print('Executando ...', data.name)    
        interpreter(data.expression, {__version__=10})
else
    print("Falha ao processar o arquivo JSON.")
end