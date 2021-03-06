# http://daringfireball.net/projects/markdown
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .*[.](markdown|md|mkd) %{
    set-option buffer filetype markdown
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook global WinSetOption filetype=markdown %{
    require-module markdown

    hook window InsertChar \n -group markdown-indent markdown-indent-on-new-line
    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window markdown-.+ }
}

hook -group markdown-load-languages global WinSetOption filetype=markdown %{
    hook -group markdown-load-languages window NormalIdle .* markdown-load-languages
    hook -group markdown-load-languages window InsertIdle .* markdown-load-languages
}


hook -group markdown-highlight global WinSetOption filetype=markdown %{
    add-highlighter window/markdown ref markdown
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/markdown }
}


provide-module markdown %{

# Highlighters
# ‾‾‾‾‾‾‾‾‾‾‾‾

add-highlighter shared/markdown regions
add-highlighter shared/markdown/inline default-region regions
add-highlighter shared/markdown/inline/text default-region group

evaluate-commands %sh{
  languages="
    awk c cabal clojure coffee cpp css cucumber d diff dockerfile fish
    gas go haml haskell html ini java javascript json julia kak kickstart
    latex lisp lua makefile markdown moon objc perl pug python ragel
    ruby rust sass scala scss sh swift toml tupfile typescript yaml sql
  "
  for lang in ${languages}; do
    printf 'add-highlighter shared/markdown/%s region -match-capture ^(\h*)```\h*(%s|\\{[.=]?%s\\}))\\b   ^(\h*)``` regions\n' "${lang}" "${lang}" "${lang}"
    printf 'add-highlighter shared/markdown/%s/ default-region fill meta\n' "${lang}"
    [ "${lang}" = kak ] && ref=kakrc || ref="${lang}"
    printf 'add-highlighter shared/markdown/%s/inner region \A```[^\\n]*\K (?=```) ref %s\n' "${lang}" "${ref}"
  done
}

add-highlighter shared/markdown/codeblock region -match-capture \
    ^(\h*)```\h* \
    ^(\h*)```\h*$ \
    fill meta

add-highlighter shared/markdown/listblock region ^\h*[-*]\s ^\h*((?=[-*])|$) regions
add-highlighter shared/markdown/listblock/g default-region group
add-highlighter shared/markdown/listblock/g/ ref markdown/inline
add-highlighter shared/markdown/listblock/g/marker regex ^\h*([-*])\s 1:bullet

# https://spec.commonmark.org/0.29/#link-destination
# This repetition is not pretty but shell escaping is worse
add-highlighter shared/markdown/angle_bracket_url region (?<=<)([a-z]+://|(mailto|magnet|xmpp):) (?!\\).(?=>)|\n fill link
add-highlighter shared/markdown/url region -recurse \( ([a-z]+://|(mailto|magnet|xmpp):) (?!\\).(?=\))|\s fill link
add-highlighter shared/markdown/listblock/angle_bracket_url region (?<=<)([a-z]+://|(mailto|magnet|xmpp):) (?!\\).(?=>)|\n fill link
add-highlighter shared/markdown/listblock/url region -recurse \( ([a-z]+://|(mailto|magnet|xmpp):) (?!\\).(?=\))|\s fill link

try %{
    require-module html
    add-highlighter shared/markdown/tag region (?i)</?[a-z][a-z0-9-]*\s*([a-z_:]|(?=>)) > ref html/tag
}

add-highlighter shared/markdown/inline/code region -match-capture (`+) (`+) fill mono

# Setext-style header
add-highlighter shared/markdown/inline/text/ regex (\A|^\n)[^\n]+\n={2,}\h*\n\h*$ 0:title
add-highlighter shared/markdown/inline/text/ regex (\A|^\n)[^\n]+\n-{2,}\h*\n\h*$ 0:header

# Atx-style header
add-highlighter shared/markdown/inline/text/ regex ^#[^\n]* 0:header

add-highlighter shared/markdown/inline/text/ regex (?<!\*)(\*([^\s*]|([^\s*](\n?[^\n*])*[^\s*]))\*)(?!\*) 1:+i
add-highlighter shared/markdown/inline/text/ regex (?<!_)(_([^\s_]|([^\s_](\n?[^\n_])*[^\s_]))_)(?!_) 1:+i
add-highlighter shared/markdown/inline/text/ regex (?<!\*)(\*\*([^\s*]|([^\s*](\n?[^\n*])*[^\s*]))\*\*)(?!\*) 1:+b
add-highlighter shared/markdown/inline/text/ regex (?<!_)(__([^\s_]|([^\s_](\n?[^\n_])*[^\s_]))__)(?!_) 1:+b
add-highlighter shared/markdown/inline/text/ regex ^\h*(>\h*)+ 0:comment
add-highlighter shared/markdown/inline/text/ regex "\H( {2,})$" 1:+r@meta

# Inline code
add-highlighter shared/markdown/inline/text/ regex "^( {4}|\t)+([^\n]+)" 2:meta

# Commands
# ‾‾‾‾‾‾‾‾

define-command -hidden markdown-indent-on-new-line %{
    evaluate-commands -draft -itersel %{
        # copy block quote(s), list item prefix and following white spaces
        try %{ execute-keys -draft k <a-x> s ^\h*\K((>\h*)+([*+-]\h)?|(>\h*)*[*+-]\h)\h* <ret> y gh j P }
        # preserve previous line indent
        try %{ execute-keys -draft <semicolon> K <a-&> }
        # remove trailing white spaces
        try %{ execute-keys -draft -itersel %{ k<a-x> s \h+$ <ret> d } }
    }
}

define-command -hidden markdown-load-languages %{
    evaluate-commands -draft %{ try %{
        execute-keys 'gtGbGls```\h*\{?[.=]?\K[^}\s]+<ret>'
        evaluate-commands -itersel %{ require-module %val{selection} }
    }}
}

}
