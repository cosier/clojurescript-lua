--   Copyright (c) Rich Hickey. All rights reserved.
--   The use and distribution terms for this software are covered by the
--   Eclipse Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php)
--   which can be found in the file epl-v10.html at the root of this distribution.
--   By using this software in any fashion, you are agreeing to be bound by
--   the terms of this license.
--   You must not remove this notice, or any other, from this software.


require("json")
require("io")
require("cljs.builtins")

actions = {
   exec = function (body)
      local resp = {}
      local func, error = loadstring(body)
      if func then
	 local status, result = pcall(func)
         io.flush()
	 resp.body = tostring(result)
	 if status then
            if result and cljs and cljs.core and cljs.core.str then
               resp.body = cljs.core.str(result)
            end
	    resp.status = "OK"
	 else
	    resp.status = "ERROR"
	    if type(result) == "table" then
	       resp.body = result.message
	    end
	 end
      else
	 resp.status = "ERROR"
         resp.body = error
      end
      return resp
   end
}

function exec_server()

   local pipe_out_name = io.read()
   local pipe_in_name = io.read()
   local pipe_out = io.open(pipe_out_name, "w")
   local pipe_in = io.open(pipe_in_name, "r")

   while true do
      local a = pipe_in:read()
      local request = json.decode(a)
      pipe_out:write(json.encode(actions[request.action](request.body)) .. "\n")
      pipe_out:flush()
   end

end

exec_server()