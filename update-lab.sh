#!/bin/zsh

if [ $# -eq 0 ]
    then
        echo "Please specify the repository name."
    else
        echo Updating lab "$1" ...
        echo "1. Cloning lab repo"
        git clone git@github.com:nutanixdev/$1
        if [ $? -eq 0 ]
            then
                echo "2. Cloning lab patches"
                git clone git@github.com:nutanixdev/lab-patches-2022
                echo "3. CWD"
                cd $1
                echo "4. Copying patches"
                cp -R ../lab-patches-2022/* .
                cp ../lab-patches-2022/.gitignore .
                echo "5. Deleting old build"
                rm -Rf ./_build
                echo "6. Creating and activating Python venv then installing dependencies"
                python -m venv venv
                . venv/bin/activate
                pip install -r requirements.txt
                echo "7. Updating lab and section titles"
                find ./ -type f -exec sed -i -e 's/Lab Content/Lab Content/g' {} \;
                find ./ -type f -exec sed -i -e 's/_lab-content/_lab-content/g' {} \;
                sed -i -e 's/  .. example\/index//g' index.rst
                echo "8. Removing old files from main content repo"
                rm -Rf ../lab-content-2022/$1
                mkdir -p ../lab-content-2022/$1
                echo "9. Building lab"
                sphinx-build . ./_build
                echo "10. Updating main lab content repo"
                cp -R ./_build/* ../lab-content-2022/$1
                echo "11. Committing changes to lab repo"
                git add --all .
                git commit -m "Update lab repo in-line with new lab host outside HoW"
                git push -u origin master
                echo "12. Running lab"
                sphinx-autobuild --host 0.0.0.0 . ./_build
            else
                echo ""
                echo "Repo clone failed.  Are you sure the repository name is valid?"
                echo ""
            fi
fi
