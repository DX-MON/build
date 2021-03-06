--
-- Copyright (c) 2017 Milos Tosic. All rights reserved.
-- License: http://www.opensource.org/licenses/BSD-2-Clause
--
-- Based on Qt4 build script from Kyle Hendricks <kyle.hendricks@gentex.com> 
-- and Josh Lareau <joshua.lareau@gentex.com>
--

qt = {}
qt.version = "5" -- default Qt version

RTM_QT_FILES_PATH_MOC	= "../.qt/qt_moc"
RTM_QT_FILES_PATH_UI	= "../.qt/qt_ui"
RTM_QT_FILES_PATH_QRC	= "../.qt/qt_qrc"
RTM_QT_FILES_PATH_TS	= "../.qt/qt_qm"

QT_LIB_PREFIX		= "Qt" .. qt.version



function qtConfigure( _config, _projectName, _mocfiles, _qrcfiles, _uifiles, _tsfiles, _libsToLink, _copyDynamicLibraries, _is64bit, _dbgPrefix )
		
		local sourcePath			= getProjectPath(_projectName) .. "src/"
		local QT_PREBUILD_LUA_PATH	= '"' .. RTM_ROOT_DIR .. "build/qtprebuild.lua" .. '"'

		-- Defaults
		local qtEnv = string.upper(_ACTION);
		if _is64bit then
			qtEnv = "QTDIR_" .. qtEnv .. "_x64"
		else
			qtEnv = "QTDIR_" .. qtEnv .. "_x86"
		end
				
		local QT_PATH = "";

		if os.is("windows") then
			QT_PATH = os.getenv(qtEnv)
			if QT_PATH == nil then
				print ("The " .. qtEnv .. " environment variable must be set to the Qt root directory to use qtpresets5.lua")
				os.exit()
			end
		end

		flatten( _mocfiles )
		flatten( _qrcfiles )
		flatten( _uifiles )
		flatten( _tsfiles )				

		local QT_MOC_FILES_PATH = sourcePath .. RTM_QT_FILES_PATH_MOC
		local QT_UI_FILES_PATH	= sourcePath .. RTM_QT_FILES_PATH_UI
		local QT_QRC_FILES_PATH = sourcePath .. RTM_QT_FILES_PATH_QRC
		local QT_TS_FILES_PATH	= sourcePath .. RTM_QT_FILES_PATH_TS

		recreateDir( QT_MOC_FILES_PATH )
		recreateDir( QT_QRC_FILES_PATH )
		recreateDir( QT_UI_FILES_PATH )
		recreateDir( QT_TS_FILES_PATH )

		local LUAEXE = "lua "
		if os.is("windows") then
			LUAEXE = "lua.exe "
		end

		local addedFiles = {}

		-- Set up Qt pre-build steps and add the future generated file paths to the pkg
		for _,file in ipairs( _mocfiles ) do
			local mocFile = stripExtension(file)
			local mocFileBase = path.getbasename(file)
			local mocFilePath = QT_MOC_FILES_PATH .. "/" .. mocFileBase .. "_moc.cpp"

			local headerSrc = readFile(file);
			if headerSrc:find("Q_OBJECT") then
				local moc_header = path.getrelative(path.getdirectory(mocFilePath), file)
				prebuildcommands { LUAEXE .. QT_PREBUILD_LUA_PATH .. ' -moc "' .. path.getabsolute(file) .. '" "' .. QT_PATH .. '" "' .. _projectName .. '" "' .. moc_header .. '"' }

				local mocAbsolutePath = path.getabsolute(mocFilePath)
				files { file, mocAbsolutePath }
				table.insert(addedFiles, file)
			end
		end

		for _,file in ipairs( _qrcfiles ) do
			local qrcFile = stripExtension( file )
			local qrcFilePath = QT_QRC_FILES_PATH .. "/" .. path.getbasename(file) .. "_qrc.cpp"
			prebuildcommands { LUAEXE .. QT_PREBUILD_LUA_PATH .. ' -rcc "' .. path.getabsolute(file) .. '" "' .. QT_PATH .. '"' .. " " .. _projectName }

			local qrcAbsolutePath = path.getabsolute(qrcFilePath)
			files { file, qrcAbsolutePath }
			table.insert(addedFiles, qrcAbsolutePath)
		end

		for _,file in ipairs( _uifiles ) do
			local uiFile = stripExtension( file )
			local uiFilePath = QT_UI_FILES_PATH .. "/" .. path.getbasename(file) .. "_ui.h"
			prebuildcommands { LUAEXE .. QT_PREBUILD_LUA_PATH .. ' -uic "' .. path.getabsolute(file) .. '" "' .. QT_PATH .. '"' .. " " .. _projectName }
			local uiAbsolutePath = path.getabsolute(uiFilePath)
			files { file, uiAbsolutePath }
			table.insert(addedFiles, uiAbsolutePath)
		end

		for _,file in ipairs( _tsfiles ) do
			local tsFile = stripExtension( file )
			local tsFilePath = QT_TS_FILES_PATH .. "/" .. path.getbasename(file) .. "_ts.qm"
			prebuildcommands { LUAEXE .. QT_PREBUILD_LUA_PATH .. ' -ts "' .. path.getabsolute(file) .. '" "' .. QT_PATH .. '"' .. " " .. _projectName }
			local tsAbsolutePath = path.getabsolute(tsFilePath)
			files { file, tsAbsolutePath }
			table.insert(addedFiles, tsAbsolutePath)
		end				

		local pathAdd = ""
		for _,dir in ipairs(_config) do
			pathAdd = pathAdd .. "/" .. dir
		end
		local subDir = getTargetOS() .. "/" .. getTargetCompiler() .. pathAdd .. "/" 				
		local binDir = RTM_BUILD_DIR .. subDir .. solution().name.. "/bin/"
	
		if os.is("windows") then

			if _copyDynamicLibraries then

				local destPath = binDir
				destPath = string.gsub( destPath, "([/]+)", "\\" )

				for _, lib in ipairs( _libsToLink ) do
					local libname =  QT_LIB_PREFIX .. lib  .. _dbgPrefix .. '.dll'
					local source = QT_PATH .. '\\bin\\' .. libname
					local dest = destPath .. libname

					if not os.isdir(destPath) then
						mkdir(destPath)
					end
					if not os.isdir(destPath .. "/platforms") then
						mkdir(destPath .. "/platforms")
					end
					if not os.isfile(dest) then
						os.copyfile( source, dest )
					end
				end

				otherDLLNames = {}
				otherDLLSrcPrefix = {}
				otherDLLDstPrefix = {}

				if _ACTION:find("vs") then
					otherDLLNames = { "libEGL" .. _dbgPrefix , "libGLESv2" .. _dbgPrefix, "qwindows" .. _dbgPrefix, "qminimal" .. _dbgPrefix }
					otherDLLSrcPrefix = { "\\bin\\", "\\bin\\", "\\plugins\\platforms\\", "\\plugins\\platforms\\" }
					otherDLLDstPrefix = { "", "", "platforms\\", "platforms\\" }
				end

				if _ACTION:find("gmake") then
					otherDLLNames = { "icudt52", "icuin52", "icuuc52", "qwindows" .. _dbgPrefix, "qminimal" .. _dbgPrefix }
					otherDLLSrcPrefix = { "\\bin\\", "\\bin\\", "\\bin\\", "\\plugins\\platforms\\", "\\plugins\\platforms\\" }
					otherDLLDstPrefix = { "", "", "", "platforms\\", "platforms\\" }
				end
					
				for i=1, #otherDLLNames, 1 do
					local libname =  otherDLLNames[i] .. '.dll'
					local source = QT_PATH .. otherDLLSrcPrefix[i] .. libname
					local dest = destPath .. '\\' .. otherDLLDstPrefix[i] .. libname
					if not os.isfile(dest) then
						mkdir(path.getdirectory(dest))
						os.copyfile( source, dest )
					end
				end
			end

			defines { "QT_THREAD_SUPPORT", "QT_USE_QSTRINGBUILDER" }

			local libsDirectory = QT_PATH .. "/lib/"

			configuration { _config }
			libdirs { libsDirectory }

			configuration { _config }

			includedirs	{ QT_PATH .. "/include" }
			includedirs	{ QT_PATH .. "/qtwinextras/include" }
				
			if _ACTION:find("vs") then
					-- Qt rcc doesn't support forced header inclusion - preventing us to do PCH in visual studio (gcc accepts files that don't include pch)
					buildoptions( "/FI" .. '"' .. _projectName .. "_pch.h" .. '"' .. " " )
					-- 4127 conditional expression is constant
					-- 4275 non dll-interface class 'stdext::exception' used as base for dll-interface class 'std::bad_cast'
					buildoptions( "/wd4127 /wd4275" ) 
			end

			for _, lib in ipairs( _libsToLink ) do
				local libDebug = libsDirectory .. QT_LIB_PREFIX .. lib .. "d" -- .. ".lib"
				local libRelease = libsDirectory .. QT_LIB_PREFIX .. lib -- .. ".lib"

				configuration { "debug", _config }
					links( libDebug )

				configuration { "not debug", _config }
					links( libRelease )
			end
	
			configuration { _config }

		else
			local qtLinks = QT_LIB_PREFIX .. table.concat( libsToLink, " " .. QT_LIB_PREFIX )

			local qtLibs  = "pkg-config --libs " .. qtLinks
			local qtFlags = "pkg-config --cflags " .. qtLinks
			local libPipe = io.popen( qtLibs, 'r' )
			local flagPipe= io.popen( qtFlags, 'r' )

			qtLibs = libPipe:read( '*line' )
			qtFlags = flagPipe:read( '*line' )
			libPipe:close()
			flagPipe:close()

			configuration { _config }
			buildoptions { qtFlags }
			linkoptions { qtLibs }
		end

	configuration {}
	return addedFiles
end

