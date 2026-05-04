#include <bits/stdc++.h>
using namespace std;

char M[300][4];
char IR[4], R[4];
int IC;
bool C;
int SI, PI, TI;
int PTR;
int TTC, LLC;
int TTL, TLL;

ifstream fin;
ofstream fout;

vector<int> usedFrames;
int wordPtr = 0;
bool terminated = false;
string jobID = "";
bool endConsumed = false;

void init()
{
    for (int i = 0; i < 300; i++)
        for (int j = 0; j < 4; j++)
            M[i][j] = ' ';

    for (int i = 0; i < 4; i++)
        IR[i] = R[i] = ' ';

    IC = 0;
    C = false;
    SI = PI = TI = 0;
    TTC = LLC = 0;
    wordPtr = 0;
    terminated = false;
    usedFrames.clear();
    endConsumed = false;
}

int allocateFrame()
{
    if ((int)usedFrames.size() >= 30)
        return -1;

    while (true)
    {
        int f = rand() % 30;
        if (find(usedFrames.begin(), usedFrames.end(), f) == usedFrames.end())
        {
            usedFrames.push_back(f);
            return f;
        }
    }
}

void printJobInfo(const string &errorMsg)
{
    fout << "Job ID: " << jobID << "\n";
    fout << "  " << errorMsg << "\n";
    fout << "IC : " << IC << "\n";
    fout << "IR : " << IR[0] << IR[1] << IR[2] << IR[3] << "\n";
    fout << "TTC : " << TTC << "\n";
    fout << "TTL : " << TTL << "\n";
    fout << "LLC : " << LLC << "\n";
    fout << "TLL : " << TLL << "\n";
}

void terminate(int EM)
{
    fout << "\n";
    switch (EM)
    {
    case 0: printJobInfo("No Error");                break;
    case 1: printJobInfo("OUT OF DATA");             break;
    case 2: printJobInfo("LINE LIMIT EXCEEDED");     break;
    case 3: printJobInfo("TIME LIMIT EXCEEDED");     break;
    case 4: printJobInfo("OPERATION CODE ERROR");    break;
    case 5: printJobInfo("OPERAND ERROR");           break;
    case 6: printJobInfo("INVALID PAGE FAULT");      break;
    }
    fout << "\n";
    terminated = true;
}

int addressMap(int VA)
{
    if (VA < 0 || VA > 99)
    {
        PI = 2;
        return -1;
    }
    int page = VA / 10;
    int PTE = PTR + page;

    if (M[PTE][0] == '*')
    {
        PI = 3;
        return -1;
    }
    if (!isdigit(M[PTE][2]) || !isdigit(M[PTE][3]))
    {
        PI = 2;
        return -1;
    }

    int frame = (M[PTE][2] - '0') * 10 + (M[PTE][3] - '0');
    return frame * 10 + (VA % 10);
}

void MOS()
{
    if (terminated) return;

    if (TI == 2)
    {
        terminate(3);
        return;
    }

    if (PI != 0)
    {
        if (PI == 3)
        {
            if ((IR[0] == 'G' && IR[1] == 'D') ||
                (IR[0] == 'S' && IR[1] == 'R'))
            {
                int VA = (IR[2] - '0') * 10 + (IR[3] - '0');
                int page = VA / 10;
                int frame = allocateFrame();
                if (frame == -1)
                {
                    terminate(6);
                    return;
                }
                M[PTR + page][0] = '0';
                M[PTR + page][1] = '0';
                M[PTR + page][2] = (char)((frame / 10) + '0');
                M[PTR + page][3] = (char)((frame % 10) + '0');
                PI = 0;
                return;
            }
            else
            {
                terminate(6);
                return;
            }
        }
        else if (PI == 1) terminate(4);
        else if (PI == 2) terminate(5);
        return;
    }

    if (SI == 1)
    {
        string line;
        if (!getline(fin, line) || line.substr(0, 4) == "$END")
        {
            if (line.substr(0, 4) == "$END") endConsumed = true;
            terminate(1);
            return;
        }
        int VA = (IR[2] - '0') * 10 + (IR[3] - '0');
        int RA = addressMap(VA);
        if (PI != 0)
        {
            MOS();
            if (terminated) return;
            PI = 0;
            RA = addressMap(VA);
            if (PI != 0) { terminate(5); return; }
        }

        int k = 0;
        for (int i = RA; i < RA + 10; i++)
            for (int j = 0; j < 4; j++)
                M[i][j] = (k < (int)line.length()) ? line[k++] : ' ';
        SI = 0;
    }
    else if (SI == 2)
    {
        LLC++;
        if (LLC > TLL)
        {
            terminate(2);
            return;
        }
        int VA = (IR[2] - '0') * 10 + (IR[3] - '0');
        int RA = addressMap(VA);
        if (PI != 0)
        {
            MOS();
            if (terminated) return;
            PI = 0;
            RA = addressMap(VA);
            if (PI != 0) { terminate(5); return; }
        }

        for (int i = RA; i < RA + 10; i++)
            for (int j = 0; j < 4; j++)
                fout << M[i][j];
        fout << "\n";
        SI = 0;
    }
    else if (SI == 3)
    {
        terminate(0);
    }
}

void executeUserProgram()
{
    while (!terminated)
    {
        if (TTC > TTL)
        {
            TI = 2;
            MOS();
            return;
        }

        int RA = addressMap(IC);
        if (PI != 0)
        {
            int page = IC / 10;
            int frame = allocateFrame();
            if (frame == -1 || PI == 2)
            {
                terminate(PI == 2 ? 5 : 6);
                return;
            }
            M[PTR + page][0] = '0';
            M[PTR + page][1] = '0';
            M[PTR + page][2] = (char)((frame / 10) + '0');
            M[PTR + page][3] = (char)((frame % 10) + '0');
            PI = 0;
            continue;
        }

        memcpy(IR, M[RA], 4);
        IC++;
        TTC++;

        if (IR[0] == 'H')
        {
            SI = 3;
            MOS();
            return;
        }

        if (!isdigit(IR[2]) || !isdigit(IR[3]))
        {
            PI = 2;
            MOS();
            return;
        }

        string op(IR, IR + 2);

        if (op == "GD")
        {
            SI = 1;
            MOS();
        }
        else if (op == "PD")
        {
            SI = 2;
            MOS();
        }
        else if (op == "LR")
        {
            int VA = (IR[2] - '0') * 10 + (IR[3] - '0');
            int loc = addressMap(VA);
            if (PI != 0)
            {
                MOS();
                if (!terminated) { IC--; TTC--; }
                continue;
            }
            memcpy(R, M[loc], 4);
        }
        else if (op == "SR")
        {
            int VA = (IR[2] - '0') * 10 + (IR[3] - '0');
            int loc = addressMap(VA);
            if (PI != 0)
            {
                MOS();
                if (!terminated) { IC--; TTC--; }
                continue;
            }
            memcpy(M[loc], R, 4);
        }
        else if (op == "CR")
        {
            int VA = (IR[2] - '0') * 10 + (IR[3] - '0');
            int loc = addressMap(VA);
            if (PI != 0)
            {
                MOS();
                if (!terminated) { IC--; TTC--; }
                continue;
            }
            C = (memcmp(R, M[loc], 4) == 0);
        }
        else if (op == "BT")
        {
            int VA = (IR[2] - '0') * 10 + (IR[3] - '0');
            if (C)
                IC = VA;
        }
        else
        {
            PI = 1;
            MOS();
            return;
        }
    }
}

void loadWord(char c0, char c1, char c2, char c3)
{
    int page = wordPtr / 10;
    if (page >= 10) { terminate(6); return; }

    if (M[PTR + page][0] == '*')
    {
        int frame = allocateFrame();
        if (frame == -1) { terminate(6); return; }
        M[PTR + page][0] = '0';
        M[PTR + page][1] = '0';
        M[PTR + page][2] = (char)((frame / 10) + '0');
        M[PTR + page][3] = (char)((frame % 10) + '0');
    }

    int frame = (M[PTR + page][2] - '0') * 10 + (M[PTR + page][3] - '0');
    int physAddr = frame * 10 + (wordPtr % 10);

    M[physAddr][0] = c0;
    M[physAddr][1] = c1;
    M[physAddr][2] = c2;
    M[physAddr][3] = c3;

    wordPtr++;
}

void load()
{
    string line;
    while (getline(fin, line))
    {
        if (line.empty()) continue;

        if (line.substr(0, 4) == "$AMJ")
        {
            init();
            jobID = line.substr(4, 4);
            TTL = stoi(line.substr(8, 4));
            TLL = stoi(line.substr(12, 4));

            int ptFrame = allocateFrame();
            if (ptFrame == -1) { fout << "OUT OF MEMORY\n"; return; }
            PTR = ptFrame * 10;

            for (int i = PTR; i < PTR + 10; i++)
                M[i][0] = M[i][1] = M[i][2] = M[i][3] = '*';
        }
        else if (line.substr(0, 4) == "$DTA")
        {
            executeUserProgram();
            // Drain any unread data lines until $END
            if (!endConsumed)
            {
                string skipLine;
                while (getline(fin, skipLine))
                {
                    if (skipLine.substr(0, 4) == "$END") break;
                }
            }
        }
        else if (line.substr(0, 4) == "$END")
        {
            continue;
        }
        else
        {
            int k = 0;
            int lineLen = (int)line.length();

            while (k < lineLen)
            {
                char c[4] = {' ', ' ', ' ', ' '};
                for (int j = 0; j < 4; j++)
                    if (k < lineLen) c[j] = line[k++];

                loadWord(c[0], c[1], c[2], c[3]);
                if (terminated) return;
            }
        }
    }
}

int main()
{
    srand((unsigned)time(0));
    fin.open("input2.txt");
    fout.open("output2.txt");

    if (!fin.is_open())
    {
        cout << "Error opening input.txt\n";
        return 1;
    }

    load();

    fin.close();
    fout.close();
    cout << "MOS Phase 2 Execution Completed!\n";
    return 0;
}