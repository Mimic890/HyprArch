# Disable the greeting message
function fish_greeting; end

# Run fastfetch only in interactive sessions
if status is-interactive
    fastfetch
end
