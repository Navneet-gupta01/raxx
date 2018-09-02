defmodule Raxx.View do
  defmacro __using__(options) do
    {options, []} = Module.eval_quoted(__CALLER__, options)

    {arguments, options} = Keyword.pop_first(options, :arguments, [])

    {page_template, options} =
      Keyword.pop_first(options, :template, Raxx.View.template_for(__CALLER__.file))

    page_template = Path.expand(page_template, Path.dirname(__CALLER__.file))

    {layout_template, []} = Keyword.pop_first(options, :layout)

    layout_template =
      if layout_template do
        Path.expand(layout_template, Path.dirname(__CALLER__.file))
      end

    arguments = Enum.map(arguments, fn a when is_atom(a) -> {a, [line: 1], nil} end)

    compiled_page = EEx.compile_file(page_template)

    compiled_layout =
      if layout_template do
        EEx.compile_file(layout_template)
      else
        {:__page__, [], nil}
      end

    {compiled, has_page} =
      Macro.prewalk(compiled_layout, false, fn
        {:__page__, _opts, nil}, _acc ->
          {compiled_page, true}

        ast, acc ->
          {ast, acc}
      end)

    IO.inspect(has_page)

    quote do
      # TODO get warning for unused argument
      # This should take a response/request
      def html(unquote_splicing(arguments)) do
        unquote(compiled)
      end
    end
  end

  def template_for(file) do
    case String.split(file, ~r/\.ex(s)?$/) do
      [path_and_name, ""] ->
        path_and_name <> ".html.eex"

      _ ->
        raise "#{__MODULE__} needs to be used from a `.ex` or `.exs` file"
    end
  end
end
