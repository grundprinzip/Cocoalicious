-- main.applescript
-- Convert Posts To URLs

--  Created by Buzz Andersen on 10.09.05.
--  Copyright 2005 __MyCompanyName__. All rights reserved.

on run {input, parameters}
	set output to {}
	tell application "Cocoalicious"
		repeat with x in input
			if the class of x is tag then
				set end of output to name of x
			end if
		end repeat
	end tell
	return output
end run
