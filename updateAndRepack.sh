mkdir tmp
tar -xvzf dc.tar.gz -C ./tmp
rm dc.tar.gz
cd tmp
sh bin/dependency-check.sh -f HTML -o . -s ./* -project update
rm dependency-check-report.html
tar -czvf dc.tar.gz ./*
mv dc.tar.gz ../dc.tar.gz
cd ..
rm -rf tmp
