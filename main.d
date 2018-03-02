static import std.getopt;
static import std.stdio;
static import std.file;
static import std.conv;
static import std.algorithm;
static import std.utf;
static import std.regex;
static import std.string;
static import std.array;
static import std.ascii;
static import core.thread;
static import core.time;

alias among = std.algorithm.comparison.among;
alias byChar = std.utf.byChar;

class bfSimulator
{
	private int pointer = 0;
	private int[int] memory;
	private string output;

	this(char[] program)
	{
		this.execute(program);
	}

	public string getOutput()
	{
		return this.output;
		//
	}

	private int execute(char[] code)
	{
		for (int i = 0; i < code.length; i++)
		{
			if (code[i] == "+"[0])
			{
				this.t_INCREMENT();
			}
			else if (code[i] == "-"[0])
			{
				this.t_DECREMENT();
			}
			else if (code[i] == ">"[0])
			{
				this.t_SHIFT_RIGHT();
			}
			else if (code[i] == "<"[0])
			{
				this.t_SHIFT_LEFT();
			}
			else if (code[i] == "."[0])
			{
				this.t_OUTPUT();
			}
			else if (code[i] == ","[0])
			{
				this.t_INPUT();
			}
			else if (code[i] == "["[0])
			{
				if (this.memory[this.pointer] == 0)
				{
					for (;code[i] != "]"[0]; i++) {}
				}
				else
				{
					int start = i+1;
					for (;code[i] != "]"[0]; i++) {}
					int end = i;

					char[] temp;
					for (int s = start; s < end; s++)
					{
						temp ~= code[s];
					}
					this.execute(temp);
					i = start -2;
				}
			}
		}
		return 0;
	}

	private int t_INCREMENT()
	{
		if (this.pointer !in this.memory)
		{
			this.memory[this.pointer] = 1;
		}
		else if (this.memory[this.pointer] != 255)
		{
			this.memory[this.pointer]++;
		}
		else
		{
			this.memory[this.pointer] = 0;
		}
		return 0;
	}
	private int t_DECREMENT()
	{
		if (this.pointer !in this.memory)
		{
			this.memory[this.pointer] = 255;
		}
		else if (this.memory[this.pointer] != 0)
		{
			this.memory[this.pointer]--;
		}
		else
		{
			this.memory[this.pointer] = 255;
		}
		return 0;
	}
	private int t_SHIFT_LEFT()
	{
		this.pointer--;
		return 0;
	}
	private int t_SHIFT_RIGHT()
	{
		this.pointer++;
		return 0;
	}
	private int t_INPUT()
	{
		std.stdio.writeln("Program requires input, enter a value 000-255");
		bool run = true;
		char[] input;
		while (run)
		{
			std.stdio.write(">> ");
			std.stdio.readln(input);
			if (input.length != 3)
			{
				std.stdio.writeln("Program requires a 3-long integer (000-255), retry");
			}
			else if (!std.string.isNumeric(cast(string)input))
			{
				std.stdio.writeln("Program requires a 3-long integer (000-255), retry");
			}
			else if (std.conv.to!int(input) > 255)
			{
				std.stdio.writeln("Program requires a 3-long integer (000-255), retry");
			}
			else
			{
				this.memory[this.pointer] = std.conv.to!int(input);
			}
		}
		return 0;
	}
	private int t_OUTPUT()
	{
		this.output ~= cast(char)this.memory[this.pointer];
		return 0;
	}
}

int main(string[] args)
{
	// target file
	char[] progCode;
	{
		string tempCode;
		string input;
		// Determine file
		string filepath;

		std.getopt.GetoptResult helpi;
		try {
			helpi = std.getopt.getopt(args,
				std.getopt.config.required,
				"file|f", "Path to the target file", &filepath);
		}
		catch (std.getopt.GetOptException e)
		{
			std.stdio.writeln(e.msg);
			std.stdio.writeln("\nConsider running with --help");
			return 0;
		}
		catch (Exception e)
		{
			std.stdio.writeln(e.msg);
			std.stdio.writeln("\nConsider running with --help");
			return 0;
		}

		if (helpi.helpWanted)
		{
			std.getopt.defaultGetoptPrinter("A command line interpreter for the BrainFuck language\n",helpi.options);
			return 0;
		}

		if (!std.file.exists(filepath))
		{
			std.stdio.writeln("That file does not exist");
			return 0;
		}

		// Gather contents, check for discrepancies
		char[] prog;
		int inputs = 0;
		int brackets = 0;
		try {
			prog = std.conv.to!string(std.file.read(filepath.byChar)).dup;
		}
		catch (std.file.FileException e)
		{
			std.stdio.writeln(e.msg);
			return 0;
		}

		for (int i = 0; i < prog.length; i++)
		{
			if (std.conv.to!string(prog[i]).among("<",">","+","-",".",",","[","]"))
			{
				tempCode ~= prog[i];
			}

			if (std.conv.to!string(prog[i]) == "[")
			{
				brackets++;
			}
			if (std.conv.to!string(prog[i]) == "]")
			{
				brackets--;
			}
		}

		if (brackets != 0)
		{
			std.stdio.writeln("Discrepancy: Brackets do not match");
			return 0;
		}
		progCode = tempCode.dup;
	}

	std.stdio.writeln("Executing code...");
	// Simulation
	bfSimulator sim = new bfSimulator(progCode);

	std.stdio.writeln("Output: "~sim.getOutput());
	return 0;
}