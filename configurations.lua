--
-- Copyright (c) 2017 Milos Tosic. All rights reserved.
-- License: http://www.opensource.org/licenses/BSD-2-Clause
--

local params = { ... }

local SOURCE_FILES		= params[1] or false
local EXTRA_CONFIG		= params[2] or nil
local IS_LIBRARY		= params[3] or false
local IS_SHARED_LIBRARY	= params[4] or false
local COPY_QT_DLLS		= params[5] or false
local WITH_QT			= params[6] or false
local WITH_RAPP			= params[7] or false

dofile (RTM_SCRIPTS_DIR .. "embedded_files.lua")
dofile (RTM_SCRIPTS_DIR .. "qtpresets5.lua")
dofile (RTM_SCRIPTS_DIR .. "toolchain.lua")

function setSubConfig(_subConfig, _configuration, _is64bit)
	commonConfig({ _subConfig, _configuration }, IS_LIBRARY, IS_SHARED_LIBRARY, WITH_RAPP)
	shaderConfigure({ _subConfig, _configuration }, project().name, shaderFiles)
	local prefix = ""
	if _configuration == "debug" then
		prefix = "d"
	end
	if WITH_QT then
		qtAddedFiles = qtConfigure({ _subConfig, _configuration }, project().name, mocFiles, qrcFiles, uiFiles, tsFiles, libsToLink, COPY_QT_DLLS, _is64bit, prefix )
	end
end

function setConfig(_configuration)
	setSubConfig("x32",		_configuration, false)
	setSubConfig("x64",		_configuration, true)
	setSubConfig("native",	_configuration, true)
end

configuration {}

local qtAddedFiles = {}

-- debug configurations
configuration { "debug" } 
	targetsuffix "_debug"
	defines { Defines_Debug }
	flags   { ExtraFlags_Debug }

setConfig("debug")

-- release configurations
configuration { "release" }
	targetsuffix "_release"
	defines { Defines_Release }
	flags   { ExtraFlags_Release }

setConfig("release")
	
	-- retail configurations
configuration { "retail" }
	targetsuffix "_retail"
	defines { Defines_Retail }
	flags   { ExtraFlags_Retail }

setConfig("retail")

configuration {}
 if EXTRA_CONFIG then
	 EXTRA_CONFIG()
 end

function vpathFilter(_string, _find)

	-- lib samples
	local pathPos = string.find(_string, "/samples/")
	if pathPos ~= nil then
		local vpath = string.sub(_string, pathPos + string.len("/samples/"), string.findlast(_string, "/"))
		local replaceStart = string.find(vpath, "/")
		return "src" .. string.sub(vpath, replaceStart, string.len(vpath))
	end

	-- lib tests
	local pathPos = string.find(_string, "/test/")
	if pathPos ~= nil then
		local vpath = string.sub(_string, pathPos + string.len("/test/"), string.len(_string))
		local slash = string.findlast(vpath, "/")
		if slash ~= nil then
			return "src/" .. string.sub(vpath, 1, slash)
		end
		return "src"
	end

	-- lib tools
	local pathPos = string.find(_find, "_tool_")
	if pathPos ~= nil then
		local projectDirName = "/" .. string.sub(_find, pathPos + string.len("_tool_"), string.len(_find)) .. "/"
		local vpath = string.sub(_string, string.find(_string, projectDirName) + string.len(projectDirName), string.len(_string))
		local slash = string.findlast(vpath, "/")
		if slash ~= nil then
			return "src/" .. string.sub(vpath, 1, slash)
		end
		return "src"
	end

	-- 
	local pos = string.find(_string, _find)
	if pos ~= nil then
		local rem = string.sub(_string, pos + string.len(_find) + 1)
		pos = string.findlast(rem, "/")

		if pos ~= nil then
			return string.sub(rem, 1, pos-1)
		end
	end

	local lsPos = string.findlast(_string, "/") - 1
	local plPos = string.findlast(_string, "/", lsPos) + 1
	local name = string.sub(_string, plPos, lsPos)

	if name == "inc" then
		return "inc"
	end

	return "src"
end

SOURCE_FILES = mergeTables(SOURCE_FILES, qtAddedFiles)

for _,srcFilePattern in ipairs(SOURCE_FILES) do
	local srcFiles = os.matchfiles(srcFilePattern)
	if string.find(srcFilePattern, "%*%*") == nil then
		srcFiles = { srcFilePattern }
	end
	for _,srcFile in ipairs(srcFiles) do
		
		if string.endswith(srcFile, ".ui") then
			vpaths { ["qt/forms"]			= srcFile }
		end
		
		if string.endswith(srcFile, ".qrc") then
			vpaths { ["qt/resources"]		= srcFile }
		end

		local filtered = false
		if	string.endswith(srcFile, "_ui.h") then
			filtered = true
			vpaths { ["qt/generated/ui"]	= srcFile }
		end

		if	string.endswith(srcFile, "_moc.cpp") then
			filtered = true
			vpaths { ["qt/generated/moc"]	= srcFile }
		end

		if	string.endswith(srcFile, "_qrc.cpp") then
			filtered = true
			vpaths { ["qt/generated/qrc"]	= srcFile }
		end
		
		if	string.endswith(srcFile, ".ts") then
			vpaths { ["qt/translation"]		= srcFile }
		end

		if	string.endswith(srcFile, ".h")		or
			string.endswith(srcFile, ".hpp")	or
			string.endswith(srcFile, ".inl")	or
			string.endswith(srcFile, ".c")		or
			string.endswith(srcFile, ".cc")		or
			string.endswith(srcFile, ".cpp")	then
			if not filtered then
				vpaths { [vpathFilter(srcFile, project().name)]		= srcFile }
			end
		end
	end
end

