-- main.applescript
-- Convert Posts To URLs

--  Created by Armin on 24.05.05.
--  Copyright 2005 __MyCompanyName__. All rights reserved.

on run {input, parameters}
	set output to {}
	tell application "Cocoalicious"
		repeat with x in input
			if the class of x is post then
				set end of output to url of x
			end if
		end repeat
	end tell
	return output
end run
