defmodule Qrit.CLI do
  @moduledoc """
  QRIT - QR Code generator from stdin or from a file

  Usage:

  # send output to terminal

  ./qrit -f source_file
  cat source_file | ./qrit

  # send output to PNG files

  ./qrit -f source_file --to-file
  cat source_file | ./qrit --to-file
  
  Options:
  -f            source file to read data from to be made into QR code
  -h | --help   show this help message
  --to-file     send output data to file(s)
  """
  def main(args) do
    options = [
      strict: [
        file: :string,
        to_file: :boolean,
        help: :boolean
      ],
      aliases: [
        f: :file,
        h: :help
      ]
    ]

    {opts, _, invalid} = OptionParser.parse(args, options)

    if length(invalid) != 0 do
      IO.puts "Invalid command line parameter #{invalid}"
    end

    if opts[:help] == true do
      print_usage()
    end
  
    stream = cond do
      opts[:file] == nil ->
        IO.stream(:stdio, :line)
      true ->
        File.stream!(opts[:file])
    end

    if opts[:to_file] == true do 
      # send output to file
      stream
      |> Stream.map(fn data -> qrify(data, "png") end)
      |> Stream.with_index
      |> Stream.map(fn {data, index} -> File.write("out_#{index}.png", data, [:binary]) end)
      |> Stream.run
    else
      # send output to terminal
      stream
      |> Stream.map(fn data -> qrify(data, "terminal") end)
      |> Stream.run
    end
  end

  defp print_usage() do
    IO.puts @moduledoc
    exit(:shutdown)
  end

  defp qrify(data, type) do
    case type do
      "png" ->
        data
        |> String.trim
        |> EQRCode.encode()
        |> EQRCode.png()
      "terminal" ->
        data
        |> String.trim
        |> EQRCode.encode()
        |> EQRCode.render()
    end
  end
end
