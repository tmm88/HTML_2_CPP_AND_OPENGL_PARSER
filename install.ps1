# PowerShell script to set up and compile visualizer project
# Run as Administrator: Right-click PowerShell, "Run as Administrator"

# Step 1: Install MSYS2
$msys2Installer = "C:\Users\selfd\Downloads\msys2-installer.exe"
$msys2Url = "https://github.com/msys2/msys2-installer/releases/download/nightly-x86_64/msys2-x86_64-latest.exe"
$msys2Path = "C:\msys64"

if (-not (Test-Path $msys2Path)) {
    Write-Host "Downloading MSYS2 installer..."
    Invoke-WebRequest -Uri $msys2Url -OutFile $msys2Installer
    Write-Host "Installing MSYS2 to $msys2Path..."
    Start-Process -FilePath $msys2Installer -ArgumentList "--accept-licenses --install-dir $msys2Path --no-start" -Wait
}

# Step 2: Install MSYS2 dependencies
Write-Host "Installing MSYS2 dependencies..."
$bashCommand = @"
pacman -Syu --noconfirm
pacman -S --noconfirm mingw-w64-x86_64-cmake mingw-w64-x86_64-gcc mingw-w64-x86_64-make mingw-w64-x86_64-zlib mingw-w64-x86_64-libpng mingw-w64-x86_64-bzip2 mingw-w64-x86_64-glfw mingw-w64-x86_64-glew
pacman -S --noconfirm mingw-w64-x86_64-libbrotlidec || echo "libbrotlidec not found, proceeding without it"
"@
$bashCommand | & "$msys2Path\usr\bin\bash.exe" --login

# Step 3: Create project directories
$projectDir = "C:\Users\selfd\Desktop\_"
$libDir = "$projectDir\lib"
$includeDir = "$projectDir\include"
Write-Host "Creating project directories..."
New-Item -Path $libDir -ItemType Directory -Force
New-Item -Path $includeDir -ItemType Directory -Force

# Step 4: Copy GLFW, GLEW, and FreeType DLL
Write-Host "Copying GLFW, GLEW, and FreeType files..."
Copy-Item -Path "$msys2Path\mingw64\lib\libglfw3.a" -Destination $libDir -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$msys2Path\mingw64\include\GLFW" -Recurse -Destination $includeDir -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$msys2Path\mingw64\bin\glfw3.dll" -Destination $projectDir -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$msys2Path\mingw64\lib\libglew32.a" -Destination $libDir -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$msys2Path\mingw64\include\GL" -Recurse -Destination $includeDir -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$msys2Path\mingw64\bin\glew32.dll" -Destination $projectDir -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$msys2Path\mingw64\bin\libfreetype-6.dll" -Destination "$projectDir\freetype.dll" -Force -ErrorAction SilentlyContinue

# Step 5: Copy font
Write-Host "Copying arial.ttf..."
Copy-Item -Path "C:\Windows\Fonts\arial.ttf" -Destination $projectDir -Force -ErrorAction SilentlyContinue

# Step 6: Create test.html
Write-Host "Creating test.html..."
@"
<h1>hello world!!!</h1>
<div><p>my name is tiago and i am 37 years old!!!</p></div>
<div><p>nice to meet you    !!!</p></div>
"@ | Set-Content -Path "$projectDir\test.html"

# Step 7: Build FreeType 2.14.0
Write-Host "Building FreeType 2.14.0..."
$freeTypeDir = "C:\Users\selfd\Downloads\openglStack\ft2140\freetype-2.14.0"
if (-not (Test-Path $freeTypeDir)) {
    Write-Host "Downloading FreeType 2.14.0..."
    New-Item -Path "C:\Users\selfd\Downloads\openglStack\ft2140" -ItemType Directory -Force
    Invoke-WebRequest -Uri "https://sourceforge.net/projects/freetype/files/freetype2/2.14.0/freetype-2.14.0.tar.gz" -OutFile "C:\Users\selfd\Downloads\openglStack\ft2140\freetype-2.14.0.tar.gz"
    & "$msys2Path\usr\bin\bash.exe" -c "cd /c/Users/selfd/Downloads/openglStack/ft2140 && tar -xzf freetype-2.14.0.tar.gz"
}
$buildDir = "$freeTypeDir\builds"
New-Item -Path $buildDir -ItemType Directory -Force
$cmakeCommand = @"
cd /c/Users/selfd/Downloads/openglStack/ft2140/freetype-2.14.0/builds
cmake -G "MinGW Makefiles" -DCMAKE_INSTALL_PREFIX=/c/Users/selfd/Desktop/_ -DBUILD_SHARED_LIBS=OFF -DFT_WITH_ZLIB=ON -DFT_WITH_PNG=ON -DFT_WITH_BZIP2=ON -DFT_WITH_BROTLI=OFF ..
mingw32-make
mingw32-make install
"@
$cmakeCommand | & "$msys2Path\usr\bin\bash.exe" --login

# Step 8: Copy libraries to MinGW
Write-Host "Copying libraries to MinGW..."
$mingwLibDir = "C:\mingw\mingw64\lib"
New-Item -Path $mingwLibDir -ItemType Directory -Force
Copy-Item -Path "$libDir\libfreetype.a" -Destination $mingwLibDir -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$libDir\libglfw3.a" -Destination $mingwLibDir -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$libDir\libglew32.a" -Destination $mingwLibDir -Force -ErrorAction SilentlyContinue

# Step 9: Compile visualizer.cpp with MinGW
Write-Host "Compiling visualizer.cpp with MinGW..."
$mingwPath = "C:\mingw\mingw64\bin\g++.exe"
cd $projectDir
if (Test-Path $mingwPath) {
    & $mingwPath -o visualizer.exe visualizer.cpp -std=c++17 -I include -L lib -lglfw3 -lglew32 -lopengl32 -lfreetype
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully compiled visualizer.exe"
    } else {
        Write-Host "Compilation of visualizer.cpp failed"
        exit 1
    }
} else {
    Write-Host "MinGW not found, using MSYS2 g++..."
    $compileCommand = @"
cd /c/Users/selfd/Desktop/_
g++ -o visualizer.exe visualizer.cpp -std=c++17 -I include -L lib -lglfw3 -lglew32 -lopengl32 -lfreetype
"@
    $compileCommand | & "$msys2Path\usr\bin\bash.exe" --login
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully compiled visualizer.exe with MSYS2"
    } else {
        Write-Host "Compilation of visualizer.cpp failed with MSYS2"
        exit 1
    }
}

# Step 10: Run visualizer.exe
Write-Host "Running visualizer.exe..."
cd $projectDir
.\visualizer.exe test.html
if ($LASTEXITCODE -eq 0) {
    Write-Host "Successfully ran visualizer.exe"
} else {
    Write-Host "Failed to run visualizer.exe"
    exit 1
}

# Step 11: Compile generated_output.cpp with MinGW
Write-Host "Compiling generated_output.cpp with MinGW..."
cd $projectDir
if (Test-Path $mingwPath) {
    & $mingwPath -o generated_output.exe generated_output.cpp -std=c++17 -I include -L lib -lglfw3 -lglew32 -lopengl32 -lfreetype
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully compiled generated_output.exe"
    } else {
        Write-Host "Compilation of generated_output.cpp failed"
        exit 1
    }
} else {
    $compileGeneratedCommand = @"
cd /c/Users/selfd/Desktop/_
g++ -o generated_output.exe generated_output.cpp -std=c++17 -I include -L lib -lglfw3 -lglew32 -lopengl32 -lfreetype
"@
    $compileGeneratedCommand | & "$msys2Path\usr\bin\bash.exe" --login
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully compiled generated_output.exe with MSYS2"
    } else {
        Write-Host "Compilation of generated_output.cpp failed with MSYS2"
        exit 1
    }
}

# Step 12: Run generated_output.exe
Write-Host "Running generated_output.exe..."
cd $projectDir
.\generated_output.exe
if ($LASTEXITCODE -eq 0) {
    Write-Host "Successfully ran generated_output.exe"
} else {
    Write-Host "Failed to run generated_output.exe"
    exit 1
}

Write-Host "Setup and compilation complete! Check for a window displaying text."