#pragma once
#include <string>
#include <vector>
#include <opencv2/core.hpp>

std::vector<std::string> getTiffFiles(const std::string &folder);
cv::Mat readImageCleaned(const std::string &path);
void saveImage(const std::string &path, const cv::Mat &img);