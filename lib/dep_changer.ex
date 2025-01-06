defmodule DepChanger do
  @moduledoc """
  Documentation for `DepChanger`.
  """

  def problem_statement do
    original =
      "mix.exs"
      |> File.read!()

    try do
      new = String.replace(original, "[]", "[{:jason, \">= 0.0.0\"}]")

      File.write!("mix.exs", new)

      # What can I do to compile this new dependency, and any other dependencies
      # with an optional dependency on it?
      # I can't restart the VM, we have in memory state of file changes
      # and igniter is invoked via a mix task
    after
      # cleanup
      File.write!("mix.exs", original)
    end
  end

  # example implementation
  # this doesn't work, I'm not sure why yet as its similar to what
  # we do in igniter which does work. I'm trying to minimize or eliminate
  # private API usage.
  def swap_and_recompile do
    original =
      "mix.exs"
      |> File.read!()

    try do
      new = String.replace(original, "[]", "[{:jason, \">= 0.0.0\"}]")

      File.write!("mix.exs", new)

      Mix.Project.clear_deps_cache()
      Mix.Project.pop()
      Mix.Dep.clear_cached()

      old_undefined = Code.get_compiler_option(:no_warn_undefined)
      old_relative_paths = Code.get_compiler_option(:relative_paths)
      old_ignore_module_conflict = Code.get_compiler_option(:ignore_module_conflict)

      try do
        Code.compiler_options(
          relative_paths: false,
          no_warn_undefined: :all,
          ignore_module_conflict: true
        )

        System.cmd("mix", ["deps.get"]) |> IO.inspect()

        _ = Code.compile_file("mix.exs")

        Mix.Dep.load_and_cache()
      after
        Code.compiler_options(
          relative_paths: old_relative_paths,
          no_warn_undefined: old_undefined,
          ignore_module_conflict: old_ignore_module_conflict
        )
      end
    after
      File.write!("mix.exs", original)
    end
  end
end
