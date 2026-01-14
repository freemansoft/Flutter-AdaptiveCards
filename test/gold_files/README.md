# Golden Files are Linux based images generated and tested on the build server

## Updating the golden files

The simplest way to get a GitHub aligned test image is to.
1. Download the artifacts zip file created from a failed build
2. Examine the failed test images to make sure the changes are expected
3. Rename the `xxx_testImage.png` files to `xxx.png` for any of the failed tests.
4. Copy the renamed files to the `test/gold_files` directory.
5. Commit the changes to the repository.

The next build should pass.
