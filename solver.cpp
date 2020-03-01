#include <bits/stdc++.h>
using namespace std;


class Sudoku {
public:
    vector<vector<vector<int>>> pos;
    vector<vector<int>> fixed;
    int rec_cnt;
    vector<pair<pair<int, int>, int>> killer_contraints;

    Sudoku() {
        vector<int> ODD = {1, 3, 5, 7, 9};
        vector<int> EVEN = {2, 4, 6, 8};
        pos = {{EVEN, EVEN, EVEN, EVEN, ODD, ODD, ODD, ODD, ODD},
               {ODD, ODD, ODD, EVEN, ODD, ODD, EVEN, EVEN, EVEN},
               {EVEN, ODD, ODD, EVEN, EVEN, ODD, ODD, ODD, EVEN},
               {ODD, ODD, EVEN, ODD, EVEN, EVEN, ODD, ODD, EVEN},
               {ODD, EVEN, ODD, ODD, EVEN, EVEN, ODD, EVEN, ODD},
               {EVEN, EVEN, ODD, ODD, ODD, ODD, EVEN, EVEN, ODD},
               {ODD, EVEN, EVEN, ODD, ODD, EVEN, ODD, EVEN, ODD},
               {EVEN, ODD, EVEN, ODD, ODD, ODD, EVEN, ODD, EVEN},
               {ODD, ODD, ODD, EVEN, EVEN, EVEN, EVEN, ODD, ODD}};
        fixed.assign(9, vector<int>(9, 0));
        rec_cnt = 0;
        killer_contraints = {{{1, 2}, 11},
                             {{1,3}, 21},
                             {{1,4}, 17},
                             {{2,9}, 7},
                             {{3,9}, 9},
                             {{4,9}, 22},
                             {{9,6}, 9},
                             {{9,7}, 22},
                             {{9,8}, 9},
                             {{6,1}, 18},
                             {{7,1}, 13},
                             {{8,1}, 15}};
    }

    bool check_constraints() {
        bool possible = true;
        for (auto const& [start, goal] : killer_contraints)
            possible &= check_little_killer(start, goal);

        for (int row_idx = 0; row_idx < 9; row_idx++)
            possible &= check_region(fixed[row_idx]);

        for (int col_idx = 0; col_idx < 9; col_idx++) {
            vector<int> col(9);
            for (int row_idx = 0; row_idx < 9; row_idx++)
                col[row_idx] = fixed[row_idx][col_idx];
            possible &= check_region(col);
        }
        for (int row_idx = 0; row_idx < 3; row_idx++) {
            for (int col_idx = 0; col_idx < 3; col_idx++) {
                vector<int> digits;
                digits.reserve(9);
                for (int row = row_idx*3; row < row_idx*3+3; row++) {
                    for (int col = col_idx*3; col < col_idx*3+3; col++) {
                        digits.push_back(fixed[row][col]);
                    }
                }
                possible &= check_region(digits);
            }
        }
        return possible;
    }
    
    bool check_region(vector<int> const& digits) {
        vector<int> cnts(10, 0);
        for (auto digit : digits)
            cnts[digit] += 1;
        return *max_element(cnts.begin() + 1, cnts.end()) <= 1;
    }
   
    bool check_little_killer(pair<int, int> start, int goal) {
        vector<int> digits;
        for (auto [row, col] : little_killer(start)) {
            digits.push_back(fixed[row-1][col-1]);
        }
        if (accumulate(digits.begin(), digits.end(), 0) == goal && *min_element(digits.begin(), digits.end()) > 0)
            return true;
        if (accumulate(digits.begin(), digits.end(), 0) < goal && *min_element(digits.begin(), digits.end()) == 0)
            return true;
        return false;
    }
    
    vector<pair<int, int>> little_killer(pair<int, int> start) {
        auto cur = start;
        auto direction = start;
        if (start.first == 1)
            direction = {1, -1};
        if (start.first == 9)
            direction = {-1, 1};
        if (start.second == 1)
            direction = {1, 1};
        if (start.second == 9)
            direction = {-1, -1};

        vector<pair<int, int>> cells;
        while (min(cur.first, cur.second) > 0 && max(cur.first, cur.second) < 10) {
            cells.push_back(cur);
            cur = {cur.first + direction.first, cur.second + direction.second};
        }
        return cells;
    }
    
    friend ostream& operator<<(ostream& os, Sudoku sudoku) {
        for (int i = 0; i < 9; i++) {
            if (i % 3 == 0)
                os << "--- --- ---\n";
            for (int j = 0; j < 9; j++) {
                os << sudoku.fixed[i][j];
                if (j == 2 || j == 5)
                    os << "|";
                if (j == 8)
                    os << "\n";
            }
        }
        os << "--- --- ---\n";
        return os;
    }
    
    void solve_rec(int row=0, int col=0) {
        rec_cnt += 1;
        if (rec_cnt % 10'000 == 0)
            show_progress();
        for (auto value : pos[row][col]) {
            fixed[row][col] = value;
            if (check_constraints()) {
                if (row == 8 && col == 8) {
                    cout << *this << endl;
                    continue;
                }
                solve_rec(row+(col+1)/9, (col+1)%9);
            }
        }

        fixed[row][col] = 0;
    }

    void show_progress() {
        double progress = 0.;
        double full_progress = 1.;
        for (int idx = 0; idx < 9; idx++) {
            int digit = fixed[0][idx];
            if (digit == 0)
                break;
            int max_possibles = pos[0][idx].size();
            full_progress /= max_possibles;
            progress += full_progress * ((digit-1) / 2);
        }

        cout << "Progress: " << (progress * 100) << endl;
    }
};


int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(nullptr);

    Sudoku().solve_rec();
}
