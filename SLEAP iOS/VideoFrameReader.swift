//
//  VideoFrameReader.swift
//  SLEAP iOS
//
//  Created by Suraj Laddagiri  on 9/24/26.
//



import AVFoundation
import CoreMedia
import CoreVideo
import UIKit
import CoreImage


struct VideoFrame {
    let image: UIImage
    let timestamp: CMTime
}

@MainActor
final class VideoFrameReader {
    private let reader: AVAssetReader
    private let provider: AVAssetReaderOutput.Provider<CMReadySampleBuffer<CMSampleBuffer.DynamicContent>>
    private enum ReaderError: Error {
        case noVideoTrack
        case cannotAddOutput
        case unexpectedSampleType
        case imageConversionFailed
    }
    private let imageContext = CIContext()
    private let preferredTransform: CGAffineTransform

    init(url: URL) async throws {
        let asset = AVURLAsset(url: url)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let track = tracks.first else {
            throw ReaderError.noVideoTrack
        }
        self.preferredTransform = try await track.load(.preferredTransform)
        let reader = try AVAssetReader(asset: asset)

        let output = AVAssetReaderTrackOutput(track: track,outputSettings: [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA])

        guard reader.canAdd(output) else {
            throw ReaderError.cannotAddOutput
        }

        let provider = reader.outputProvider(for: output)

        try reader.start()

        self.reader = reader
        self.provider = provider
    }

    func cancel() {
        reader.cancelReading()
    }
    
    func nextFrame() async throws -> VideoFrame? {
        try Task.checkCancellation()

        // nil means the video has ended.
        guard let sample = try await provider.next() else {
            return nil
        }

        try Task.checkCancellation()

        // Extract the decoded pixel buffer.
        guard case .pixelBuffer(let pixelBuffer) = sample.content else {
            throw ReaderError.unexpectedSampleType
        }

        // Bridge to CVPixelBuffer and convert it into a CGImage.
        let cgImage = try pixelBuffer.withUnsafeBuffer { buffer in
            let transformedImage = CIImage(cvPixelBuffer: buffer)
                .transformed(by: preferredTransform)

            // Move the transformed image's origin to (0, 0).
            let bounds = transformedImage.extent

            let image = transformedImage.transformed(
                by: CGAffineTransform(
                    translationX: -bounds.minX,
                    y: -bounds.minY
                )
            )

            guard let result = imageContext.createCGImage(
                image,
                from: image.extent
            ) else {
                throw ReaderError.imageConversionFailed
            }

            return result
        }

        return VideoFrame(
            image: UIImage(
                cgImage: cgImage,
                scale: 1,
                orientation: .up
            ),
            timestamp: sample.presentationTimeStamp
        )
    }
}
