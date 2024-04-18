struct MathToken
    kind::Symbol  # :number, :variable, :operator, :lparen, :rparen
    value::Any    # value of the token (e.g., number, symbol, etc.)
end

function tokenizer(s::String)::Vector{MathToken}
    # todo
end