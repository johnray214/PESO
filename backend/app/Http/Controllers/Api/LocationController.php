<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LocationController extends Controller
{
    public function getProvinces()
    {
        $provinces = DB::table('provinces')
            ->select('id', 'name', 'region')
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $provinces
        ], 200);
    }

    public function getCities($provinceId)
    {
        $cities = DB::table('cities')
            ->where('province_id', $provinceId)
            ->select('id', 'name', 'province_id')
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $cities
        ], 200);
    }

    public function getBarangays($cityId)
    {
        $barangays = DB::table('barangays')
            ->where('city_id', $cityId)
            ->select('id', 'name', 'city_id')
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $barangays
        ], 200);
    }

    public function getAllLocations()
    {
        $provinces = DB::table('provinces')
            ->select('id', 'name', 'region')
            ->orderBy('name')
            ->get();

        $cities = DB::table('cities')
            ->select('id', 'name', 'province_id')
            ->orderBy('name')
            ->get();

        $barangays = DB::table('barangays')
            ->select('id', 'name', 'city_id')
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'provinces' => $provinces,
                'cities' => $cities,
                'barangays' => $barangays
            ]
        ], 200);
    }
}
