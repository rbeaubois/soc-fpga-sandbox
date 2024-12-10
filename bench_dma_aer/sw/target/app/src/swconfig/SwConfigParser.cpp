/*
*! @title      Software configuration
*! @file       SwConfigParser.cpp
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

#include "SwConfigParser.h"

template <typename T>
bool extract_json_variable(const json& j, const std::string& key, T& out) {
    if (!j.contains(key)) {
        std::cerr << "JSON object does not contain key: " << key << std::endl;
        return false;
    }

    try {
        out = j[key].get<T>();
        return true;
    } catch (const json::type_error& e) {
        std::cerr << "Failed to extract variable from JSON object: " << e.what() << std::endl;
        return false;
    }
}

SwConfigParser::SwConfigParser(std::string fpath_cfg){
    int r;

    // Open the configuration file
    std::ifstream config_file(fpath_cfg);
    if (!config_file.is_open()) {
        std::cerr << "Failed to open configuration file." << std::endl;
    }

    // Parse the configuration file as JSON
    json config_json;
    try {
        config_file >> config_json;
    } catch (const json::parse_error& e) {
        std::cerr << "Failed to parse configuration file: " << e.what() << std::endl;
    }

    r = !extract_json_variable(config_json, "run_time_s",                   _config.run_time_s);
    r = !extract_json_variable(config_json, "en_save_stream_ps_to_pl",      _config.en_save_stream_ps_to_pl);
    r = !extract_json_variable(config_json, "en_save_stream_pl_to_ps",      _config.en_save_stream_pl_to_ps);
    r = !extract_json_variable(config_json, "intr_thresh_free_slots_to_pl", _config.intr_thresh_free_slots_to_pl);
    r = !extract_json_variable(config_json, "intr_thresh_ready_ev_to_ps",   _config.intr_thresh_ready_ev_to_ps);
    r = !extract_json_variable(config_json, "dirpath_save_stream",          _config.dirpath_save_stream);
}

SwConfigParser::~SwConfigParser(){
}

void SwConfigParser::print(){
    print("run_time_s",                   _config.run_time_s);
    print("en_save_stream_ps_to_pl",      _config.en_save_stream_ps_to_pl);
    print("en_save_stream_pl_to_ps",      _config.en_save_stream_pl_to_ps);
    print("intr_thresh_free_slots_to_pl", (int)_config.intr_thresh_free_slots_to_pl);
    print("intr_thresh_ready_ev_to_ps",   (int)_config.intr_thresh_ready_ev_to_ps);
    print("dirpath_save_stream",          _config.dirpath_save_stream);
}

void SwConfigParser::print(std::string key, bool value){
    std::cout << key << ": " << std::boolalpha << value << std::endl;
}

void SwConfigParser::print(std::string key, int value){
    std::cout << key << ": " << value << std::endl;
}

void SwConfigParser::print(std::string key, std::string value){
    std::cout << key << ": " << value << std::endl;
}

void SwConfigParser::print(std::string key, std::vector<uint16_t> value){
    std::cout << key << ": [ ";
    for (int elem : value)
        std::cout << elem << " ";
    std::cout << "]" << std::endl;
}

struct sw_config SwConfigParser::getConfig(){
    return _config;
}
