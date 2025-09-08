#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <cstdlib>
#include <cstdio>
#include <filesystem>

std::vector<std::string> parse_html(const std::string& html) {
    std::vector<std::string> lines;
    std::string current;
    bool in_tag = false;

    for (char c : html) {
        if (c == '<') {
            in_tag = true;
            if (!current.empty()) {
                lines.push_back(current);
                current.clear();
            }
        } else if (c == '>') {
            in_tag = false;
        } else if (!in_tag && c != '\n') {
            current += c;
        }
    }
    if (!current.empty()) {
        lines.push_back(current);
    }

    // Clean up lines: trim whitespace and remove empty lines
    std::vector<std::string> cleaned_lines;
    for (auto& line : lines) {
        std::string trimmed;
        bool has_non_space = false;
        for (char c : line) {
            if (!isspace(c)) {
                has_non_space = true;
            }
            trimmed += c;
        }
        if (has_non_space) {
            cleaned_lines.push_back(trimmed);
        }
    }

    return cleaned_lines;
}

void generate_cpp_file(const std::vector<std::string>& lines, const std::string& output_cpp) {
    std::ofstream out_file(output_cpp);
    if (!out_file.is_open()) {
        std::cerr << "Error: Could not create " << output_cpp << std::endl;
        exit(1);
    }

    out_file << "#include <iostream>\n\n";
    out_file << "int main() {\n";

    for (const auto& line : lines) {
        // Escape double quotes and backslashes in the line
        std::string escaped_line;
        for (char c : line) {
            if (c == '"') {
                escaped_line += "\\\"";
            } else if (c == '\\') {
                escaped_line += "\\\\";
            } else {
                escaped_line += c;
            }
        }
        out_file << "    std::cout << \"" << escaped_line << "\" << std::endl;\n";
    }

    out_file << "    return 0;\n";
    out_file << "}\n";
    out_file.close();
    std::cout << "Generated C++ source file: " << output_cpp << std::endl;
}

bool compile_cpp_file(const std::string& cpp_file, const std::string& binary_name) {
    // Redirect compiler output to a temporary file
    std::string temp_output = "compiler_output.txt";
    std::string compile_command = "g++ -o " + binary_name + " " + cpp_file + " > " + temp_output + " 2>&1";
    int compile_result = system(compile_command.c_str());

    // Read and display compiler output
    std::ifstream compiler_out(temp_output);
    if (compiler_out.is_open()) {
        std::string line;
        while (std::getline(compiler_out, line)) {
            std::cerr << "Compiler: " << line << std::endl;
        }
        compiler_out.close();
        std::filesystem::remove(temp_output); // Clean up
    }

    if (compile_result != 0) {
        std::cerr << "Error: Compilation of " << cpp_file << " failed with exit code " << compile_result << std::endl;
        return false;
    }

    // Check if the binary was created
    if (!std::filesystem::exists(binary_name)) {
        std::cerr << "Error: Binary " << binary_name << " was not created despite successful compilation" << std::endl;
        return false;
    }

    return true;
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <html_file>" << std::endl;
        return 1;
    }

    std::ifstream file(argv[1]);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file " << argv[1] << std::endl;
        return 1;
    }

    std::string html_input;
    std::string line;
    while (std::getline(file, line)) {
        html_input += line + "\n";
    }
    file.close();

    std::vector<std::string> lines = parse_html(html_input);

    // Generate the new C++ source file
    std::string output_cpp = "generated_output.cpp";
    generate_cpp_file(lines, output_cpp);

    // Compile the generated C++ file into a binary
    std::string binary_name = "generated_output";
    if (compile_cpp_file(output_cpp, binary_name)) {
        std::cout << "Successfully generated and compiled binary: ./" << binary_name << std::endl;
    } else {
        std::cerr << "Failed to generate binary" << std::endl;
        return 1;
    }

    return 0;
}