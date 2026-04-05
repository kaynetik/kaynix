-- Path validation and escaping for wallpaper picker (allowlisted root only).

local M = {}

function M.normalize_path(p)
	if not p or p == "" then
		return ""
	end
	local x = p:gsub("/+", "/")
	if #x > 1 and x:sub(-1) == "/" then
		x = x:sub(1, -2)
	end
	return x
end

function M.path_has_dotdot(p)
	for segment in string.gmatch(p, "[^/]+") do
		if segment == ".." then
			return true
		end
	end
	return false
end

function M.is_within_root(child, root)
	if not child or not root or root == "" then
		return false
	end
	if M.path_has_dotdot(child) then
		return false
	end
	child = M.normalize_path(child)
	root = M.normalize_path(root)
	if child == root then
		return true
	end
	local prefix = root .. "/"
	if #child < #prefix then
		return false
	end
	return child:sub(1, #prefix) == prefix
end

-- Reject control chars and quotes that break shell or AppleScript wrapping.
function M.path_has_unsafe_chars(p)
	if string.find(p, '[\0\n\r"\\]') then
		return true
	end
	return false
end

function M.validate_wallpaper_path(path, root)
	if not path or path == "" then
		return nil
	end
	if M.path_has_unsafe_chars(path) then
		return nil
	end
	if not M.is_within_root(path, root) then
		return nil
	end
	return M.normalize_path(path)
end

-- Wrap for POSIX /bin/sh -c (single-quoted).
function M.shell_single_quote(s)
	return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- Inside AppleScript "..." string literals.
function M.applescript_escape_string(s)
	return (s:gsub("\\", "\\\\"):gsub('"', '\\"'))
end

-- sketchybar --set ... background.image="..." (close double quote in value must be escaped or rejected; we reject in validate)
function M.sketchybar_image_value_escape(s)
	return (s:gsub("\\", "\\\\"):gsub('"', '\\"'))
end

return M
