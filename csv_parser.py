import sys

fileName = sys.argv[1]
outFileName = sys.argv[2]

# Translates a given CSV into a Swift dictionary inside a class wrapper
# CSV Format is:
# Steam name, Steam ID, GiantBomb Name, GiantBomb ID, Manually matched ID

with open(fileName, "r") as inFile:
    with open(outFileName, "w") as outFile:
        outFile.write("class SteamMapper {\n    static let gameMappings: [Int: Int] = [\n")
        inFile.readline()   # Skip header
        line = inFile.readline().strip()
        while line != "":
            tokenized = line.split(",")
            if len(tokenized) == 5:
                if tokenized[4] != "":
                    steamId = int(tokenized[1])
                    steamName = tokenized[0]
                    gbId = int(tokenized[4])
                    stringToWrite = "        {0:>7}:{1:<5},  // {2}\n".format(steamId, gbId, steamName)
                    outFile.write(stringToWrite)
            line = inFile.readline().strip()
        outFile.write("    ]\n}\n")
