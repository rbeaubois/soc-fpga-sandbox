/*
*! @title      Software configuration
*! @file       SwConfig.h
*! @author     Romain Beaubois
*! @date       27 Apr 2023
*! @copyright
*! SPDX-FileCopyrightText: © 2023 Romain Beaubois <refbeaubois@yahoo.com>
*! SPDX-License-Identifier: GPL-3.0-or-later
*!
*! @brief
*! 
*! @details
*! > **27 Apr 2023** : file creation (RB)
*/

#ifndef __SWCONFIG_H__
#define __SWCONFIG_H__

#include <iostream>
#include <fstream>
#include <vector>
#include "../utility/json.hpp"

using json = nlohmann::json;

struct sw_config{
    int run_time_s;
    bool en_save_stream_ps_to_pl;
    bool en_save_stream_pl_to_ps;
    uint32_t intr_thresh_free_slots_to_pl;
    uint32_t intr_thresh_ready_ev_to_ps;
    std::string dirpath_save_stream;
};

class SwConfigParser{
    private:
        struct sw_config _config;
    public:
        SwConfigParser(std::string fpath_cfg);
        ~SwConfigParser();
        void print();
        void print(std::string key, bool value);
        void print(std::string key, int value);
        void print(std::string key, std::string value);
        void print(std::string key, std::vector<uint16_t> value);
        struct sw_config getConfig();
};

template <typename T>
bool extract_json_variable(const json& j, const std::string& key, T& out);

#endif