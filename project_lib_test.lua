--
-- Copyright (c) 2017 Milos Tosic. All rights reserved.
-- License: http://www.opensource.org/licenses/BSD-2-Clause
--

function addProject_lib_test(_libName, _extraConfig)

	group ("tests")
	project (_libName .. "_test")

		language	"C++"
		kind		"ConsoleApp"
		uuid		( os.uuid(project().name) )

		project().path = getProjectPath(_libName, ProjectPath.Root) .. "/test/"

		local	sourceFiles = mergeTables(	{ project().path .. "**.cpp" },
											{ project().path .. "**.h" } )
		files  { sourceFiles }
		
		addPCH( project().path, project().name )

		flags { Flags_Tests }

		assert(loadfile(RTM_SCRIPTS_DIR .. "configurations.lua"))(	sourceFiles,
																	_extraConfig,
																	false,	-- IS_LIBRARY
																	false,	-- IS_SHARED_LIBRARY
																	false,	-- COPY_QT_DLLS
																	false,	-- WITH_QT
																	false	-- WITH_RAPP
																	)

		addDependencies(_libName, { "rapp", "unittest", _libName })
end

