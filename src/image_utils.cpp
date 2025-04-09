#include "image_utils.h"
#include <filesystem>
#include <opencv2/imgcodecs.hpp>
#include <filesystem>
namespace fs = std::filesystem;

std::vector<std::string> getTiffFiles(const std::string &folder)
{
    std::vector<std::string> tiffFiles;
    for (const auto &entry : fs::directory_iterator(folder))
    {
        if (entry.path().extension() == ".tiff")
        {
            tiffFiles.push_back(entry.path().string());
        }
    }
    return tiffFiles;
}

cv::Mat readImageCleaned(const std::string &path)
{
    cv::Mat img = cv::imread(path, cv::IMREAD_GRAYSCALE);
    if (!img.empty())
    {
        // Remove padded zero rows (at bottom only)
        int nonZeroRows = img.rows;
        while (nonZeroRows > 0 && cv::countNonZero(img.row(nonZeroRows - 1)) == 0)
        {
            --nonZeroRows;
        }
        return img(cv::Range(0, nonZeroRows), cv::Range::all()).clone();
    }
    return img;
}

void saveImage(const std::string &path, const cv::Mat &img)
{
    cv::imwrite(path, img);
}