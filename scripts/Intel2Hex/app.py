import argparse
import textwrap

Parser = argparse.ArgumentParser()
Parser.add_argument("-d", "--debug", help = "Enable debug outputs.", action = "store_true")
Parser.add_argument("-i", "--input", type = str, help = "Input file.", required = True)
Parser.add_argument("-o", "--output", type = str, help = "Output file.", required = True)
args = Parser.parse_args()

Instructions = list()
if(__name__ == "__main__"):
    with open(args.input, "r") as Input:
        for Line in Input:
            Line = Line.strip().replace(":", "")
            Bytes = Line[0:2]
            Address = Line[2:6]
            Type = Line[6:8]
            Checksum = Line[-2:]
            Data = Line[8:-2]

            if(Type == "00"):
                for Instruction in textwrap.wrap(Data, 4):
                    Instructions.append(Instruction[2] + Instruction[3] + Instruction[0] + Instruction[1])

            if(args.debug):
                print("[DEBUG] Current line: {}".format(Line))
                print("     Data bytes: {}".format(Bytes))
                print("     Memory address: {}".format(Address))
                print("     Field type: {}".format(Type))
                print("     Data field: {}".format(Data))
                print("     Checksum: {}".format(Checksum))

    if(args.debug):
        print("[DEBUG] Instructions: {}".format(Instructions))

    with open(args.output, "w") as File:
        for Instruction in Instructions:
            File.write(Instruction)
            File.write("\n")