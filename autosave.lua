--@TODO: attach an autocmd to a buffer 
--@arg: output_buf: The buffer number for the output of the executable
--@arg: pattern: The pattern to trigger the autocmd
--@arg: command: The command to execute
--@arg: timer: The time to wait for the command to finish
--@notice: The timer is optional, if not provided the default value is 1000ms
--@notice: jobstart() is a blocking function, so I use jobwait() to wait for the job to finish
local attach_to_buffer = function(output_buf,pattern, command, timer)

  timer = timer or {}
  local wait_time = timer.wait_time or 1000

  vim.api.nvim_create_autocmd("BufWritePost",{
      group = vim.api.nvim_create_augroup("AutoRunGroup", {clear = false}),
      pattern = pattern,
      callback = function()
        local append_data = function(_, data)
          if data then
            vim.api.nvim_buf_set_lines(output_buf, -1, -1, false, data)
          end
        end

        vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, {"OUTPUT: "})

        local job = vim.fn.jobstart(command, {
          stdout_buffered = true,
          on_stdout = append_data,
          on_stderr = append_data,
        })

       vim.fn.jobwait({job}, wait_time) -- wait for the job to finish before executing nvim_command
    end,
  })
end

--@TODO: to {generate, build, and run} the executable 
--@arg: log_buf: The buffer number for the output of the executable
--@arg: executable_name: The name of the executable file
--@arg: run_output_buf: The buffer number for the output of the executable
vim.api.nvim_create_user_command("RunCppLog", function()
    print("Building Cpp Project...")

-- Stop any autocmds before starting a new one
    vim.api.nvim_command("AutoRunStop")

-- Generate the build directory and generate the CMake's files
    local cmake_command = {"cmake", "-Bbuild", "-H."}
    local log_buf = tonumber(vim.fn.input("Enter buffer numbr for Logging: "))
    attach_to_buffer(log_buf, "main.cpp", cmake_command)

-- Build the project
    local build_command = {"cmake", "--build", "./build"}
    coroutine.wrap(attach_to_buffer)(log_buf, "main.cpp", build_command)

-- Print the output of the executable
    vim.api.nvim_command("GetCppOutput")
end, {})

--@TODO: Add a check to see if the executable exists at path "./bin/" ... <executable_name>
--@arg: executable_name: The name of the executable file
--@arg: run_output_buf: The buffer number for the output of the executable
vim.api.nvim_create_user_command("GetCppOutput", function()
  local executable_name = vim.fn.input("Enter the name of the executable file: ")
  local run_command = {"./bin/" .. executable_name}
  local run_output_buf = tonumber(vim.fn.input("Enter buffer number for run output: "))
  attach_to_buffer(run_output_buf, "main.cpp", run_command)
end, {})

--@TODO: stop any autocmd spawed before  
vim.api.nvim_create_user_command("AutoRunStop", function()
  print "AutoRun Stopped"
  vim.api.nvim_create_augroup("AutoRunGroup", {clear = true})
end, {})

