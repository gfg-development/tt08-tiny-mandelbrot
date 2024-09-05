#include <iostream>
#include <fstream>

void generateImage(std::string filename, int scaling, int16_t offset_r, int16_t offset_i, int max_ctr, int div) {
    std::ofstream file;
    file.open(filename);

    file << "P2" << std::endl;
    file << "400 300" << std::endl;
    file << "15" << std::endl;
    
    unsigned int n;

    for (int y = 0; y < 300; y++) {
        for (int x = 0; x < 400; x++) {
            int64_t ci = scaling * y + offset_i;
            int64_t cr = scaling * x + offset_r;

            int64_t zi = 0;
            int64_t zr = 0;

            for (n = 0; n < max_ctr - 1; n++) {
                int64_t m1 = zr * zr;
                int64_t m2 = zi * zi;
                int64_t m3 = zi * zr;

                int64_t diff_m1_m2 = m1 - m2;
                int64_t t_zr = (diff_m1_m2 >> 14) + cr;
                int64_t t_zi = (m3 >> 13) + ci;

                zr = t_zr;
                zi = t_zi;

                int64_t t_sum = m1 + m2;
                if ((t_sum >> 14) > (4 << 14)) {
                    break;
                }

                if (t_zr != zr) {
                    n++;
                    break;
                }

                if (t_zi != zi) {
                    n++;
                    break;
                }
            }

            if (div == 0) {
                file << 32 - __builtin_clz(n) << " ";
            } else {
                n = (n) / div;
                if (n > 15) {
                    n = 15;
                }
                file << n << " ";
            }
        }
        file << std::endl;
    }

    file.close();
}

int main() {
    int16_t offset_i = 0xBC40; // -511 * 200 / 640 * scaling;
    int16_t offset_r = 0xF3CA; //-600 / 2 * scaling;
    
    offset_r += 250;
    offset_i += 200;

    generateImage("image1.ppm", 1, offset_r, offset_i, 64, 4);
    generateImage("image2.ppm", 4 * 4 * 4 * 2, offset_r, offset_i, 64, 4);
    generateImage("image3.ppm", 4 * 4 * 4 * 2, offset_r, offset_i, 64 * 1024, 4 * 1024);
    generateImage("image4.ppm", 4 * 4 * 4 * 2, offset_r, offset_i, 64 * 1024, 0);

    return 0;
}