import os

def list_dat_files(folder_path):
    return [f for f in os.listdir(folder_path) if f.endswith('.txt')]

if __name__ == "__main__":
    folder = os.path.dirname(__file__)
    
    for f in os.listdir(folder):
        if f.endswith('.dcm'):
            print("dicom2parrec(\"" + f + "\", \"" + f.split('.')[0] + "\")")
            
    
    
    dat_files = list_dat_files(folder)
    results = []  # List of dictionaries to store results

    for file in dat_files:
        experiment = file.split('_')[0]
        model = file.split('_')[1]
        vessel = file.split('_')[2].split('.')[0]

        vesselSharpness = None
        centerVessel = None

        with open(os.path.join(folder, file), 'r') as f:
            for line in f:
                if line.startswith("Center of vessel"):
                    centerVessel = float(line.split()[-1])
                if line.startswith("Vessel sharpness"):
                    vesselSharpness = float(line.split()[-1])
                    break

        if vesselSharpness is not None and centerVessel is not None:
            vesselSharpnessPercent = vesselSharpness / centerVessel
            result = {
                "experiment": experiment,
                "model": model,
                "vessel": vessel,
                "vesselSharpnessPercent": vesselSharpnessPercent
            }
            results.append(result)
            print(result)