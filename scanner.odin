package compiler

scanner := Scanner{}

Scanner :: struct {
    source: string,
    start: int,
    current: int,
    line: int,
}

Token :: struct {
    type: Token_Type,
    start: string,
    length: int,
    line: int,
}

Token_Type :: enum {
    Left_Paren, Right_Paren,
    Left_Brace, Right_Brace,
    Comma, Dot, Minus, Plus,
    Semicolon, Slash, Star,
    
    Bang, Bang_Equal,
    Equal, Equal_Equal,
    Greater, Greater_Equal,
    Less, Less_Equal,

    Identifier, String, Number,

    And, Class, Else, False,
    For, Fn, If, Nil, Or,
    Print, Return, Super, This,
    True, Var, While,

    Error, Eof,
}

init_scanner :: proc(source: string) {
    scanner.source = source
    scanner.start = 0
    scanner.current = 0
    scanner.line = 1
}

scan_token :: proc() -> Token {
    skip_whitespace()
    scanner.start = scanner.current

    if is_at_end() {
        return make_token(Token_Type.Eof)
    }

    c := advance_scanner()
    if is_alpha(c) do return identifier()
    if is_digit(c) do return num()

    switch c {
    case '(': return make_token(Token_Type.Left_Paren)
    case ')': return make_token(Token_Type.Right_Paren)
    case '{': return make_token(Token_Type.Left_Brace)
    case '}': return make_token(Token_Type.Right_Brace)
    case ';': return make_token(Token_Type.Semicolon)
    case ',': return make_token(Token_Type.Comma)
    case '.': return make_token(Token_Type.Dot)
    case '-': return make_token(Token_Type.Minus)
    case '+': return make_token(Token_Type.Plus)
    case '*': return make_token(Token_Type.Star)
    case '/': return make_token(Token_Type.Slash)

    case '!': return make_token(match('=') ? Token_Type.Bang_Equal : Token_Type.Bang)
    case '=': return make_token(match('=') ? Token_Type.Equal_Equal : Token_Type.Equal)
    case '<': return make_token(match('=') ? Token_Type.Less_Equal : Token_Type.Less)
    case '>': return make_token(match('=') ? Token_Type.Greater_Equal : Token_Type.Greater)

    case '"': return str()
    }

    return error_token("Unexpected character")
}

is_at_end :: proc() -> bool {
    return scanner.current >= len(scanner.source)
}

make_token :: proc(type: Token_Type) -> Token {
    token := Token{}
    token.type = type
    token.start = scanner.source
    token.length = scanner.current - scanner.start
    token.line = scanner.line
    return token
}

error_token :: proc(message: string) -> Token {
    token := Token{}
    token.type = Token_Type.Error
    token.start = message
    token.length = len(message)
    token.line = scanner.line
    return token
}

advance_scanner :: proc() -> rune {
    scanner.current += 1
    return rune(scanner.source[scanner.current - 1])
}

match :: proc(expected: rune) -> bool {
    if is_at_end() do return false
    if rune(scanner.source[scanner.current]) != expected do return false

    scanner.current += 1
    return true
}

skip_whitespace :: proc() {
    for {
        if is_at_end() do return

        c := peek()
        switch c {
        case ' ', '\r', '\t': advance_scanner()
        case '\n': 
            scanner.line += 1
            advance_scanner()
        case '/': 
            if peek_next() == '/' {
                for peek() != '\n' && is_at_end() {
                    advance_scanner()
                }

            } else {
                return
            }
        case: return
        }
    }
}

peek :: proc() -> rune {
    return rune(scanner.source[scanner.current])
}

peek_next :: proc() -> rune {
    if is_at_end() {
        return ' '
    }
    return rune(scanner.source[scanner.current + 1])
}

str :: proc() -> Token {
    for peek() != '"' && !is_at_end() {
        if peek() == '\n' do scanner.line += 1
        advance_scanner()
    }

    if is_at_end() {
        return error_token("Unterminated string.")
    }

    advance_scanner()
    return make_token(Token_Type.String)
}

is_digit :: proc(c: rune) -> bool {
    return c >= '0' && c <= '9'
}

num :: proc() -> Token {
    for is_digit(peek()) do advance_scanner()

    if peek() == '.' && is_digit(peek()) {
        advance_scanner()

        for is_digit(peek()) do advance_scanner()
    }

    return make_token(Token_Type.Number)
}

is_alpha :: proc(c: rune) -> bool {
    return (c >= 'a' && c <= 'z') ||
        (c >= 'A' && c <= 'Z') || 
        c == '_'
}

identifier :: proc() -> Token {
    for is_alpha(peek()) || is_digit(peek()) do advance_scanner()

    return make_token(identifier_type())
}

identifier_type :: proc() -> Token_Type {
    using Token_Type
    switch scanner.source[0] {
    case 'a': return check_keyword(1, 2, "nd", And)
    case 'c': return check_keyword(1, 4, "lass", Class)
    case 'e': return check_keyword(1, 3, "lse", Else)
    case 'f': 
        if scanner.current - scanner.start > 1 {
            switch scanner.source[1] {
            case 'a': return check_keyword(2, 3, "lse", False)
            case 'o': return check_keyword(2, 1, "r", For)
            case 'u': return check_keyword(2, 1, "n", Fn)
            }
        }
    case 'i': return check_keyword(1, 1, "f", If)
    case 'n': return check_keyword(1, 2, "il", Nil)
    case 'o': return check_keyword(1, 1, "r", Or)
    case 'p': return check_keyword(1, 4, "rint", Print)
    case 'r': return check_keyword(1, 5, "eturn", Return)
    case 's': return check_keyword(1, 4, "uper", Super)
    case 't': 
        if scanner.current - scanner.start > 1 {
            switch scanner.source[1] {
            case 'h': return check_keyword(2, 2, "is", This)
            case 'r': return check_keyword(2, 2, "ue", True)
            }
        }
    case 'v': return check_keyword(1, 2, "ar", Var)
    case 'w': return check_keyword(1, 4, "hile", While)
    }
    return Identifier
}

check_keyword :: proc(start: int, len: int, rest: string, type: Token_Type) -> Token_Type {
    if scanner.source[scanner.start:scanner.current] == scanner.source[start:len] && scanner.source[start:len] == rest {
        return type
    }

    return Token_Type.Identifier
}

