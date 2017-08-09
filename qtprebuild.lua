#!/usr/local/bin/lua5.1
--
-- Copyright (c) 2017 Milos Tosic. All rights reserved.
-- License: http://www.opensource.org/licenses/BSD-2-Clause
--
-- Based on script from Kyle Hendricks <kyle.hendricks@gentex.com> and
-- Josh Lareau <joshua.lareau@gentex.com>
-- ----------------------------------------------------------------------------


require("lfs")

RTM_QT_FILES_PATH_MOC	= "../.qt/qt_moc"
RTM_QT_FILES_PATH_UI	= "../.qt/qt_ui"
RTM_QT_FILES_PATH_QRC	= "../.qt/qt_qrc"
RTM_QT_FILES_PATH_TS	= "../.qt/qt_qm"

local qtDirectory = ""
qtDirectory = arg[3] or qtDirectory

local sourceDir = ""
if arg[2] ~= nil then
	local projName = arg[4]
	sourceDir = arg[2]:sub(1, arg[2]:find(projName) + string.len(projName))
	sourceDir = sourceDir .. "src/"
end

function BuildErrorWarningString( line, isError, message, code )
	if windows then
		return string.format( "qtprebuild.lua(%i): %s %i: %s", line, isError and "error" or "warning", code, message )
	else
		return string.format( "qtprebuild.lua:%i: %s: %s", line, isError and "error" or "warning", message )
	end
end

--Make sure there are at least 2 arguments
if not ( #arg >= 2 ) then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, true, "There must be at least 2 arguments supplied", 2 ) ); io.stdout:flush()
	return
end

--Checks that the first argument is either "-moc", "-uic", or "-rcc"
if not ( arg[1] == "-moc" or arg[1] == "-uic" or arg[1] == "-rcc"  or arg[1] == "-ts" ) then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[The first argument must be "-moc", "-uic", "-rcc" or "-ts"]], 3 ) ); io.stdout:flush()
	return
end

--Make sure input file exists
inputFileModTime = lfs.attributes( arg[2], "modification" )
if inputFileModTime == nil then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[The supplied input file ]]..arg[2]..[[, does not exist]], 4 ) ); io.stdout:flush()
	return
end

qtMocOutputDirectory		= sourceDir .. RTM_QT_FILES_PATH_MOC
qtUIOutputDirectory			= sourceDir .. RTM_QT_FILES_PATH_UI
qtQRCOutputDirectory		= sourceDir .. RTM_QT_FILES_PATH_QRC
qtTSOutputDirectory			= sourceDir .. RTM_QT_FILES_PATH_TS

qtMocPostfix	= "_moc"
qtQRCPostfix	= "_qrc"
qtUIPostfix		= "_ui"
qtTSPostfix		= "_ts"

windows = package.config:sub( 1, 1 ) == "\\"
del = "\\"
if not windows then
	del = "/"
end

--Set up the qt tools executable path
if windows then
	qtMocExe = qtDirectory..del.."qtbase"..del.."bin"..del..[[moc.exe]]
	qtUICExe = qtDirectory..del.."qtbase"..del.."bin"..del..[[uic.exe]]
	qtQRCExe = qtDirectory..del.."qtbase"..del.."bin"..del..[[rcc.exe]]
	qtTSExe  = qtDirectory..del.."qtbase"..del.."bin"..del..[[lrelease.exe]]
else
	qtMocExe = "moc"
	qtUICExe = "uic"
	qtQRCExe = "rcc"
	qtTSExe  = "lrelease"
end

function checkUpToDate(outputFileName) 
	outputFileModTime = lfs.attributes( outputFileName, "modification" )
	if outputFileModTime ~= nil and ( inputFileModTime < outputFileModTime ) then
		--print( outputFileName.." is up-to-date, not regenerating" )
		io.stdout:flush()
		return true
	end
	return false
end

function getFileNameNoExtFromPath( path )
	local i = 0
	local lastSlash = 0
	local lastPeriod = 0
	local returnFilename
	while true do
		i = string.find( path, "/", i+1 )
		if i == nil then break end
		lastSlash = i
	end

	i = 0
	while true do
		i = string.find( path, "%.", i+1 )
		if i == nil then break end
		lastPeriod = i
	end

	if lastPeriod < lastSlash then
		returnFilename = path:sub( lastSlash + 1 )
	else
		returnFilename = path:sub( lastSlash + 1, lastPeriod - 1 )
	end

	return returnFilename
end

getPath=function(str,sep)
    sep=sep or'/'
    return str:match("(.*"..sep..")")
end

if arg[1] == "-moc" then

	lfs.mkdir( qtMocOutputDirectory )
	outputFileName = qtMocOutputDirectory .. del .. getFileNameNoExtFromPath( arg[2] ) .. qtMocPostfix .. ".cpp"

	if checkUpToDate(outputFileName) == true then return end
	
	local fullMOCPath = qtMocExe.." \""..arg[2].. "\" -I \"" .. getPath(arg[2]) .. "\" -o \"" .. outputFileName .."\" -f".. arg[4] .. "_pch.h -f" .. arg[5] .. "\""
	if windows then
		fullMOCPath = '""'..qtMocExe..'" "'..arg[2].. '" -I "' .. getPath(arg[2]) .. '" -o "' .. outputFileName ..'"' .. " -f".. arg[4] .. "_pch.h -f" .. arg[5] .. '"'
	end

	if( 0 ~= os.execute( fullMOCPath ) ) then
		print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[MOC Failed to generate ]]..outputFileName, 5 ) ); io.stdout:flush()
	else
		--print( "MOC Created "..outputFileName )
		io.stdout:flush()
	end
elseif arg[1] == "-rcc" then
	lfs.mkdir( qtQRCOutputDirectory )
	outputFileName = qtQRCOutputDirectory .. del .. getFileNameNoExtFromPath( arg[2] ) .. qtQRCPostfix .. ".cpp"

	if checkUpToDate(outputFileName) == true then return end

	local fullRCCPath = qtQRCExe.." -name \""..getFileNameNoExtFromPath( arg[2] ).."\" \""..arg[2].."\" -o \""..outputFileName.."\""
	if windows then
		fullRCCPath = '""'..qtQRCExe..'" -name "'..getFileNameNoExtFromPath( arg[2] )..'" "'..arg[2]..'" -o "'..outputFileName..'""'
	end

	if( 0 ~= os.execute( fullRCCPath ) ) then
		print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[RCC Failed to generate ]]..outputFileName, 6 ) ); io.stdout:flush()
	else
		--print( "RCC Created "..outputFileName )
		io.stdout:flush()
	end
elseif arg[1] == "-uic" then
		lfs.mkdir( qtUIOutputDirectory )
		outputFileName = qtUIOutputDirectory .. del .. getFileNameNoExtFromPath( arg[2] ) .. qtUIPostfix .. ".h"

		if checkUpToDate(outputFileName) == true then return end

		local fullUICPath = qtUICExe.." \""..arg[2].."\" -o \""..outputFileName.."\""
		if windows then
			fullUICPath = '""'..qtUICExe..'" "'..arg[2]..'" -o "'..outputFileName..'""'
		end

		if( 0 ~= os.execute( fullUICPath ) ) then
			print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[UIC Failed to generate ]]..outputFileName, 7 ) ); io.stdout:flush()
		else
			--print( "UIC Created "..outputFileName )
			io.stdout:flush()
		end
elseif arg[1] == "-ts" then
		lfs.mkdir( qtTSOutputDirectory )
		outputFileName = qtTSOutputDirectory .. del .. getFileNameNoExtFromPath( arg[2] ) .. qtTSPostfix .. ".qm"

		if checkUpToDate(outputFileName) == true then return end

		local fullTSPath = qtTSExe.." \""..arg[2].."\""
		if windows then
			fullTSPath = '""'..qtTSExe..'" "'..arg[2]
		end

		if( 0 ~= os.execute( fullTSPath ) ) then
			print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[UIC Failed to generate ]]..outputFileName, 7 ) ); io.stdout:flush()
		else
			--print( "UIC Created "..outputFileName )
			io.stdout:flush()
		end		
end
